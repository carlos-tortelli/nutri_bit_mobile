typedef Data = Map<String, dynamic>;
Data map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Data> rows(dynamic value) =>
    value is List ? value.map(map).toList() : <Data>[];
String str(dynamic value, [String fallback = '']) =>
    value?.toString() ?? fallback;
String number(dynamic value) {
  if (value is! num) return '—';
  return (value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1))
      .replaceAll('.', ',');
}

double? decimal(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));
const goals = {
  'lose': 'Perder peso',
  'maintain': 'Manter o peso',
  'gain': 'Ganhar massa',
  'eat_better': 'Comer melhor',
};
const goalDescriptions = {
  'lose': 'Déficit calórico moderado, sem cortar nutrientes.',
  'maintain': 'Calorias no nível do seu gasto diário.',
  'gain': 'Mais calorias e proteína para treinar e crescer.',
  'eat_better': 'Refeições equilibradas, sem foco em peso.',
};
const sexes = {'F': 'Feminino', 'M': 'Masculino'};
const activities = {
  'sedentary': 'Sedentário',
  'light': 'Leve, 1 a 2 treinos por semana',
  'moderate': 'Moderado, 3 a 5 treinos por semana',
  'intense': 'Intenso, 6 ou mais treinos por semana',
};
const mealTypes = {
  'breakfast': 'Café da manhã',
  'lunch': 'Almoço',
  'snack': 'Lanche',
  'dinner': 'Jantar',
};
const profileFields = {
  'weight': 'Peso',
  'height': 'Altura',
  'birthDate': 'Data de nascimento',
  'sex': 'Sexo',
  'activityLevel': 'Nível de atividade',
  'goal': 'Objetivo',
};
String dayName(dynamic day) {
  final s = str(day);
  return ['Sábado', 'Domingo'].contains(s) ? s : '$s-feira';
}

bool gramUnit(String unit) => ['g', 'ml'].contains(unit.trim().toLowerCase());
String label(Map<String, String> options, dynamic value) =>
    options[value] ?? str(value, 'Não informado');
String dateLabel(dynamic value) {
  final date = DateTime.tryParse(str(value));
  return date == null
      ? 'Não informado'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
