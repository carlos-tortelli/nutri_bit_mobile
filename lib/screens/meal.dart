import 'dart:async';
import 'package:flutter/material.dart';
import '../models/data.dart';
import '../services/api.dart';
import '../services/food_options.dart';
import '../widgets/ui.dart';

class MealPage extends StatefulWidget {
  final Session session;
  final Data day;
  final Data? meal;
  final String subtitle;
  const MealPage({
    super.key,
    required this.session,
    required this.day,
    this.meal,
    required this.subtitle,
  });
  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, time;
  final search = TextEditingController(),
      quantity = TextEditingController(),
      unit = TextEditingController(text: 'g'),
      grams = TextEditingController();
  String? type;
  List<Data> ingredients = [], results = [];
  Data? selected;
  bool busy = false, searching = false;
  String error = '', foodError = '';
  Timer? debounce;
  int searchVersion = 0;
  Api get api => widget.session.api;
  @override
  void initState() {
    super.initState();
    final m = widget.meal ?? {};
    name = TextEditingController(text: str(m['name']));
    time = TextEditingController(text: str(m['time']));
    type = m['type'] as String?;
    ingredients = rows(m['ingredients'])
        .map(
          (i) => <String, dynamic>{
            'foodId': map(i['food'])['id'],
            'name': map(i['food'])['name'],
            'quantity': i['quantity'],
            'unit': i['unit'],
            if (i['grams'] != null) 'grams': i['grams'],
            if (i['note'] != null) 'note': i['note'],
          },
        )
        .toList();
  }

  @override
  void dispose() {
    debounce?.cancel();
    for (final c in [name, time, search, quantity, unit, grams]) {
      c.dispose();
    }
    super.dispose();
  }

  void scheduleSearch(String value) {
    debounce?.cancel();
    final version = ++searchVersion;
    setState(() {
      foodError = '';
      searching = value.trim().length >= 2;
      results = [];
    });
    if (value.trim().length < 2) return;
    debounce = Timer(
      const Duration(milliseconds: 300),
      () => findFoods(value.trim(), version),
    );
  }

  Future<void> findFoods(String value, int version) async {
    try {
      final found = rows(
        await api.get('/foods?search=${Uri.encodeQueryComponent(value)}'),
      );
      if (mounted && version == searchVersion) {
        setState(() {
          results = found;
          searching = false;
        });
      }
    } catch (e) {
      if (mounted && version == searchVersion) {
        setState(() {
          foodError = e.toString();
          searching = false;
        });
      }
    }
  }

  void selectFood(Data food) {
    setState(() {
      selected = food;
      quantity.clear();
      unit.text = 'g';
      grams.clear();
      foodError = '';
    });
  }

  void add() {
    final q = decimal(quantity.text),
        g = decimal(grams.text),
        u = unit.text.trim();
    if (selected == null ||
        q == null ||
        !q.isFinite ||
        q <= 0 ||
        u.isEmpty ||
        (!gramUnit(u) && (g == null || !g.isFinite || g <= 0)) ||
        (grams.text.trim().isNotEmpty &&
            (g == null || !g.isFinite || g <= 0))) {
      setState(
        () => foodError =
            'Informe uma quantidade positiva e, para unidades diferentes de g ou ml, o peso total em gramas.',
      );
      return;
    }
    setState(() {
      ingredients.add({
        'foodId': selected!['id'],
        'name': selected!['name'],
        'quantity': q,
        'unit': u,
        'grams': ?g,
      });
      selected = null;
      foodError = '';
    });
  }

  Future<void> showOptions(int index) async {
    final ingredient = ingredients[index];
    final chosen = await showDialog<Data>(
      context: context,
      builder: (c) => SimilarDialog(api: api, ingredient: ingredient, allowReplace: true),
    );
    if (!mounted || chosen == null) return;
    setState(() {
      ingredients[index] = {
        'foodId': chosen['id'],
        'name': chosen['name'],
        'quantity': chosen['grams'],
        'unit': 'g',
      };
    });
  }

  Future<void> removeIngredient(int index) async {
    final accepted = await confirm(context, 'Remover ${ingredients[index]['name']}?');
    if (!mounted || !accepted) return;
    setState(() => ingredients.removeAt(index));
  }

  Future<void> pickTime() async {
    final parts = time.text.split(':');
    final current = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 7,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : const TimeOfDay(hour: 7, minute: 0);
    final t = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      setState(
        () => time.text =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final data = <String, dynamic>{
        'name': name.text.trim(),
        'type': type,
        if (time.text.isNotEmpty) 'time': time.text,
        'ingredients': ingredients
            .map((i) => Map<String, dynamic>.from(i)..remove('name'))
            .toList(),
      };
      if (widget.meal == null) {
        await api.post('/days/${widget.day['id']}/meals', data);
      } else {
        await api.put('/meals/${widget.meal!['id']}', data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget mealPanel() => Panel(
    children: [
      subheading('Dados da refeição'),
      errorBox(error),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field(
              name,
              'Nome',
              hint: 'Café da manhã',
              validate: requiredText,
            ),
            dropdown(
              'Tipo',
              mealTypes,
              type,
              (v) => setState(() => type = v),
              required: true,
            ),
            TextFormField(
              controller: time,
              readOnly: true,
              onTap: pickTime,
              decoration: const InputDecoration(
                labelText: 'Horário',
                suffixIcon: Icon(Icons.schedule),
              ),
            ),
            rule(),
            subheading('Ingredientes'),
            if (ingredients.isEmpty)
              const Text('Nenhum ingrediente ainda. Busque um alimento.'),
            for (var i = 0; i < ingredients.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str(ingredients[i]['name']),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${number(ingredients[i]['quantity'])} ${ingredients[i]['unit']}${ingredients[i]['grams'] == null ? '' : ' (${number(ingredients[i]['grams'])} g)'}',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                  link(
                    'Remover',
                    busy ? null : () => removeIngredient(i),
                    destructive: true,
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => showOptions(i),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Tipos de opções'),
                ),
              ),
              const Divider(),
            ],
            gap(),
            action(
              busy ? 'Salvando…' : 'Salvar refeição',
              busy ? null : save,
            ),
            gap(8),
            OutlinedButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ],
  );
  Widget foodPanel() => Panel(
    children: [
      subheading('Buscar alimento'),
      TextField(
        controller: search,
        onChanged: scheduleSearch,
        decoration: const InputDecoration(
          labelText: 'Nome do alimento',
          hintText: 'Ex.: pão',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      gap(),
      errorBox(foodError),
      if (searching)
        loading()
      else if (results.isEmpty)
        Text(
          search.text.trim().length < 2
              ? 'Digite pelo menos 2 caracteres.'
              : 'Nenhum alimento encontrado.',
          style: const TextStyle(color: muted),
        )
      else ...[
        const Text('Valores por 100 g', style: TextStyle(color: muted)),
        for (final f in results) ...[
          Material(
            color: selected?['id'] == f['id'] ? yellow : Colors.white,
            child: InkWell(
              onTap: busy ? null : () => selectFood(f),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            str(f['name']),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${number(f['calorias'])} kcal · P ${number(f['proteinas'])} g · C ${number(f['carboidratosDisponiveis'])} g',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      selected?['id'] == f['id'] ? 'Escolhido' : 'Escolher',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
        ],
      ],
      if (selected != null) ...[
        rule(),
        subheading('Adicionar: ${selected!['name']}'),
        NutriSplit(
          breakpoint: 310,
          first: field(
            quantity,
            'Quantidade',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          second: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextField(
              controller: unit,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Unidade (g, ml, fatias…)',
              ),
            ),
          ),
        ),
        if (!gramUnit(unit.text))
          field(
            grams,
            'Peso total (g)',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        action('Adicionar ingrediente', busy ? null : add, dark: true),
      ],
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: bar(context),
    body: PageBody(
      children: [
        heading(
          widget.meal == null ? 'Nova refeição' : 'Editar refeição',
          widget.subtitle,
        ),
        NutriSplit(
          firstFlex: 4,
          secondFlex: 6,
          first: mealPanel(),
          second: foodPanel(),
        ),
      ],
    ),
  );
}

class SimilarDialog extends StatefulWidget {
  final Api api;
  final Data ingredient;
  final bool allowReplace;
  const SimilarDialog({
    super.key,
    required this.api,
    required this.ingredient,
    this.allowReplace = false,
  });
  @override
  State<SimilarDialog> createState() => _SimilarDialogState();
}

class _SimilarDialogState extends State<SimilarDialog> {
  late Future<FoodOptions> future;
  @override
  void initState() {
    super.initState();
    future = loadFoodOptions(widget.api, widget.ingredient);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: const RoundedRectangleBorder(),
    title: const Text('Tipos de opções'),
    content: SizedBox(
      width: 430,
      child: FutureBuilder<FoodOptions>(
        future: future,
        builder: (c, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return loading();
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                errorBox('Não foi possível buscar opções: ${snapshot.error}'),
                link('Tentar novamente', () => setState(() {
                  future = loadFoodOptions(widget.api, widget.ingredient);
                })),
              ],
            );
          }
          final options = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Alimento original', style: TextStyle(color: muted)),
                Text(str(options.original['name']), style: const TextStyle(fontWeight: FontWeight.w800)),
                statLine('${number(options.original['grams'])} g', '${number(options.original['calorias'])} kcal'),
                rule(),
                subheading('Alternativas'),
                const Text('Porções aproximadas com calorias semelhantes. Proteínas e carboidratos podem variar.', style: TextStyle(color: muted)),
                gap(),
                if (options.extraUnavailable)
                  const Text('Algumas opções extras não puderam ser consultadas.', style: TextStyle(color: muted)),
                if (options.alternatives.isEmpty)
                  const Text('Nenhuma substituição disponível.'),
                for (final item in options.alternatives) ...[
                  Text(str(item['name']), style: const TextStyle(fontWeight: FontWeight.w800)),
                  statLine('${number(item['grams'])} g', '${number(item['caloriasEquivalentes'])} kcal'),
                  if (widget.allowReplace)
                    Align(
                      alignment: Alignment.centerRight,
                      child: link('Trocar', () => Navigator.pop(context, item)),
                    ),
                  const Divider(),
                ],
                if (widget.allowReplace)
                  const Text('A troca só será gravada ao salvar a refeição.', style: TextStyle(color: muted)),
              ],
            ),
          );
        },
      ),
    ),
    actions: [link('Fechar', () => Navigator.pop(context))],
  );
}
