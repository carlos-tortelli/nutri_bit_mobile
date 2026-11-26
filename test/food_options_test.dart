import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_bit_mobile/services/api.dart';
import 'package:nutri_bit_mobile/services/food_options.dart';

void main() {
  test('Equivalência de 100 g de arroz com batata-doce do banco', () {
    final result = equivalentFood({'id': 223, 'calorias': 145}, 131)!;
    expect(result['grams'], 90);
    expect(result['caloriasEquivalentes'], 130.5);
    expect(equivalentFood({'calorias': null}, 131), isNull);
    expect(equivalentFood({'calorias': 0}, 131), isNull);
  });

  test('Peso explícito tem prioridade e unidades caseiras exigem gramas', () {
    expect(ingredientGrams({'quantity': 2, 'unit': 'fatias', 'grams': 60}), 60);
    expect(ingredientGrams({'quantity': 100, 'unit': 'g'}), 100);
    expect(ingredientGrams({'quantity': 2, 'unit': 'fatias'}), isNull);
    expect(ingredientGrams({'quantity': 0, 'unit': 'g'}), isNull);
  });

  test('Consulta opções existentes e inclui batata preparada sem alterar API', () async {
    final api = Api(client: MockClient((request) async {
      expect(request.method, 'GET');
      final path = request.url.path;
      final query = request.url.queryParameters;
      Object data = [];
      if (path.endsWith('/foods/178/similar')) {
        expect(query['grams'], '100');
        expect(query['limit'], '5');
        data = {
          'food': {'id': 178, 'name': 'Arroz polido, cozido', 'grams': 100, 'calorias': 131},
          'similar': [{'id': 122, 'name': 'Arroz integral', 'grams': 121, 'caloriasEquivalentes': 130.7}],
        };
      } else if (query['search'] == 'Batata') {
        data = [
          {'id': 223, 'name': 'Batata doce, assada', 'calorias': 145},
          {'id': 224, 'name': 'Batata, baroa, crua', 'calorias': 87},
          {'id': 334, 'name': 'Batata, cozida', 'calorias': null},
          {'id': 314, 'name': 'Batata frita', 'calorias': 315},
        ];
      }
      return http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
    }));
    addTearDown(api.close);
    final options = await loadFoodOptions(api, {
      'food': {'id': 178}, 'quantity': 100, 'unit': 'g',
    });
    expect(options.alternatives.map((i) => i['id']), [223, 122]);
    expect(options.alternatives.first['grams'], 90);
    expect(options.original['calorias'], 131);
    expect(options.extraUnavailable, false);
  });
}
