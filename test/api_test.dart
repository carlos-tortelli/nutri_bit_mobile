import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_bit_mobile/services/api.dart';
import 'package:nutri_bit_mobile/models/data.dart';

void main() {
  test(
    'Login aceita 201, guarda JWT e envia Bearer nas rotas privadas',
    () async {
      final api = Api(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/auth/login')) {
            expect(jsonDecode(req.body), {
              'email': 'teste@example.com',
              'password': '123456',
            });
            return http.Response(
              jsonEncode({
                'access_token': 'jwt-teste',
                'user': {'sub': 1, 'role': 'user', 'name': 'Teste'},
              }),
              201,
            );
          }
          expect(req.headers['Authorization'], 'Bearer jwt-teste');
          return http.Response('[]', 200);
        }),
      );
      final session = Session(api);
      await session.authenticate(
        email: 'teste@example.com',
        password: '123456',
      );
      expect(session.loggedIn, true);
      expect(await api.get('/meal-plans'), isEmpty);
      session.dispose();
    },
  );
  test('Cadastro envia passwordHash conforme DTO do servidor', () async {
    final api = Api(
      client: MockClient((req) async {
        expect(jsonDecode(req.body), {
          'name': 'Teste',
          'email': 'teste@example.com',
          'passwordHash': '123456',
        });
        return http.Response(
          '{"access_token":"jwt","user":{"sub":1,"role":"user"}}',
          201,
        );
      }),
    );
    final session = Session(api);
    await session.authenticate(
      name: 'Teste',
      email: 'teste@example.com',
      password: '123456',
    );
    expect(session.admin, false);
    session.dispose();
  });
  test('401 em rota privada encerra a sessão', () async {
    final api = Api(
      client: MockClient(
        (_) async => http.Response('{"message":"Unauthorized"}', 401),
      ),
    );
    final session = Session(api)..user = {'sub': 1};
    api.token = 'expired';
    await expectLater(api.get('/profiles/me'), throwsA(isA<ApiException>()));
    expect(session.loggedIn, false);
    expect(api.token, isNull);
    session.dispose();
  });
  test('Conversão de unidades e números', () {
    expect(decimal('1,5'), 1.5);
    expect(gramUnit('ML'), true);
    expect(gramUnit('fatias'), false);
    expect(number(2.5), '2,5');
  });
  test('Textos e dados da API preservam acentos em UTF-8', () async {
    expect(mealTypes['breakfast'], 'Café da manhã');
    expect(mealTypes['lunch'], 'Almoço');
    expect(dayName('Sábado'), 'Sábado');
    expect(label(goals, null), 'Não informado');
    expect(number(null), '—');
    final api = Api(
      client: MockClient((req) async {
        expect(req.headers['Content-Type'], 'application/json; charset=utf-8');
        expect(jsonDecode(utf8.decode(req.bodyBytes)), {'name': 'João'});
        return http.Response.bytes(
          utf8.encode(jsonEncode({'name': 'João', 'food': 'Pão de centeio'})),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(api.close);
    expect(await api.post('/users', {'name': 'João'}), {
      'name': 'João',
      'food': 'Pão de centeio',
    });
  });
}
