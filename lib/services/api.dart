import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/data.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  final Data details;
  ApiException(this.status, this.message, [this.details = const {}]);
  @override
  String toString() => message;
}

class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const configured = String.fromEnvironment('API_URL');
  static String get baseUrl => configured.isNotEmpty
      ? configured.replaceFirst(RegExp(r'/$'), '')
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000/api'
            : 'http://localhost:3000/api');
  String? token;
  void Function()? onUnauthorized;
  Future<dynamic> request(
    String method,
    String path, {
    Data? body,
    bool auth = true,
  }) async {
    final req = http.Request(method, Uri.parse('$baseUrl$path'));
    req.headers['Accept'] = 'application/json';
    final requestToken = token;
    if (auth && requestToken != null) {
      req.headers['Authorization'] = 'Bearer $requestToken';
    }
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.bodyBytes = utf8.encode(jsonEncode(body));
    }
    late http.Response response;
    try {
      response = await _client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException(
        0,
        'Tempo de conexão esgotado. Confira o servidor.',
      );
    } on http.ClientException {
      throw ApiException(
        0,
        'Não foi possível conectar à API em $baseUrl.',
      );
    }
    dynamic result;
    if (response.bodyBytes.isNotEmpty) {
      try {
        result = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        result = null;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final details = map(result);
      final msg = details['message'];
      if (response.statusCode == 401 &&
          auth &&
          requestToken != null &&
          requestToken == token) {
        onUnauthorized?.call();
      }
      throw ApiException(
        response.statusCode,
        msg is List
            ? msg.join(', ')
            : str(msg, 'Erro HTTP ${response.statusCode}'),
        details,
      );
    }
    return result;
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, [Data? body]) =>
      request('POST', path, body: body);
  Future<dynamic> put(String path, Data body) =>
      request('PUT', path, body: body);
  Future<dynamic> delete(String path) => request('DELETE', path);
  void close() => _client.close();
}

class Session extends ChangeNotifier {
  final Api api;
  Data? user;
  Session(this.api) {
    api.onUnauthorized = logout;
  }
  bool get admin => user?['role'] == 'admin';
  bool get loggedIn => user != null;
  Future<void> authenticate({
    required String email,
    required String password,
    String? name,
  }) async {
    final data = map(
      await api.request(
        'POST',
        name == null ? '/auth/login' : '/auth/register',
        auth: false,
        body: name == null
            ? {'email': email, 'password': password}
            : {'name': name, 'email': email, 'passwordHash': password},
      ),
    );
    final account = map(data['user']);
    if (data['access_token'] is! String || account.isEmpty) {
      throw ApiException(0, 'Resposta de autenticação inválida.');
    }
    api.token = data['access_token'] as String;
    user = account;
    notifyListeners();
  }

  void logout() {
    if (user == null && api.token == null) return;
    api.token = null;
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}
