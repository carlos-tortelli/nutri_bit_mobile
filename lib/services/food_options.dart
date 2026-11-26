import '../models/data.dart';
import 'api.dart';

/// Usa o mesmo critério de conversão de unidades do servidor.
num? ingredientGrams(Data ingredient) {
  final value = ingredient['grams'] ??
      (gramUnit(str(ingredient['unit'])) ? ingredient['quantity'] : null);
  return value is num && value.isFinite && value > 0 ? value : null;
}

/// Equivalência energética arredondada ao grama mais próximo.
Data? equivalentFood(Data food, num originalCalories) {
  final calories = food['calorias'];
  if (calories is! num || !calories.isFinite || calories <= 0 ||
      !originalCalories.isFinite || originalCalories <= 0) {
    return null;
  }
  final grams = (originalCalories * 100 / calories).round();
  if (grams <= 0) return null;
  return {
    ...food,
    'grams': grams,
    'caloriasEquivalentes': (calories * grams / 10).round() / 10,
  };
}

bool _preparedStarch(String name, String term) {
  final text = name.toLowerCase();
  return text.startsWith(term.toLowerCase()) &&
      RegExp(r'cozid|assad').hasMatch(text) &&
      !RegExp(r'cru[ao]|frit|creme|mistura|dado importad').hasMatch(text);
}

class FoodOptions {
  final Data original;
  final List<Data> alternatives;
  final bool extraUnavailable;
  const FoodOptions(this.original, this.alternatives, {this.extraUnavailable = false});
}

/// Reutiliza a rota existente e complementa arroz/tubérculos no próprio app.
Future<FoodOptions> loadFoodOptions(Api api, Data ingredient) async {
  final grams = ingredientGrams(ingredient);
  final id = ingredient['foodId'] ?? map(ingredient['food'])['id'];
  if (grams == null || id == null) {
    throw const FormatException('Informe o peso do ingrediente em gramas para comparar.');
  }
  final result = map(await api.get('/foods/$id/similar?grams=$grams&limit=5'));
  final original = map(result['food']);
  final originalCalories = original['calorias'];
  if (originalCalories is! num || !originalCalories.isFinite || originalCalories <= 0) {
    throw const FormatException('O alimento não possui calorias suficientes para calcular opções.');
  }
  final regular = rows(result['similar']).where((item) {
    final weight = item['grams'];
    return item['id'] != null && item['id'] != id && weight is num && weight.isFinite && weight > 0;
  }).toList();
  final name = str(original['name']).toLowerCase();
  final terms = name.startsWith('arroz')
      ? ['Batata', 'Mandioca', 'Inhame']
      : (['batata', 'mandioca', 'inhame'].any((term) => name.startsWith(term))
          ? ['Arroz']
          : <String>[]);
  final extra = <Data>[];
  var extraUnavailable = false;
  for (final term in terms) {
    try {
      final foods = rows(await api.get('/foods?search=${Uri.encodeQueryComponent(term)}'));
      for (final food in foods) {
        if (food['id'] == null || food['id'] == id || !_preparedStarch(str(food['name']), term)) {
          continue;
        }
        final option = equivalentFood(food, originalCalories);
        if (option != null) extra.add(option);
      }
    } catch (_) {
      extraUnavailable = true;
    }
  }
  final seen = <dynamic>{id};
  return FoodOptions(original, [
    for (final option in [...extra, ...regular])
      if (seen.add(option['id'])) option,
  ].take(10).toList(), extraUnavailable: extraUnavailable);
}
