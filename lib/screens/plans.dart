import 'package:flutter/material.dart';
import '../models/data.dart';
import '../services/api.dart';
import '../widgets/ui.dart';
import 'meal.dart';

class PlansPage extends StatefulWidget {
  final Session session;
  final VoidCallback goProfile;
  const PlansPage({super.key, required this.session, required this.goProfile});
  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  Data profile = {};
  List<Data> plans = [], templates = [];
  bool busy = true, hasProfile = false, changing = false;
  String error = '', suggestionError = '';
  Api get api => widget.session.api;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      busy = true;
      error = '';
      suggestionError = '';
    });
    try {
      try {
        profile = map(await api.get('/profiles/me'));
        hasProfile = true;
      } on ApiException catch (e) {
        if (e.status != 404) rethrow;
        hasProfile = false;
        profile = {};
      }
      if (hasProfile) {
        plans = rows(await api.get('/meal-plans'));
        try {
          templates = rows(await api.get('/meal-plans/templates'));
        } on ApiException catch (e) {
          templates = [];
          if (e.status != 400 && e.status != 404) suggestionError = e.message;
        }
      } else {
        plans = [];
        templates = [];
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> showPlan(dynamic id) async {
    await open(context, PlanPage(session: widget.session, id: id));
    if (mounted) await load();
  }

  Future<void> create() async {
    if (!hasProfile) {
      widget.goProfile();
      return;
    }
    final result = await open<Data>(
      context,
      PlanFormPage(session: widget.session, initial: {'goal': profile['goal']}),
    );
    if (result != null && mounted) await showPlan(result['id']);
  }

  Future<void> useTemplate(Data template) async {
    if (changing) return;
    setState(() => changing = true);
    try {
      final result = map(
        await api.post('/meal-plans/templates/${template['id']}/use'),
      );
      if (mounted) await showPlan(result['id']);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  Future<void> remove(Data p) async {
    if (changing ||
        !await confirm(
          context,
          'Excluir o plano ${p['name']} e todas as suas refeições?',
        ) ||
        !mounted) {
      return;
    }
    setState(() => changing = true);
    try {
      await api.delete('/meal-plans/${p['id']}');
      await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => changing = false);
    }
  }

  Widget templateCard(Data t) => Panel(
    children: [
      if (t['bestMatch'] == true)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            color: yellow,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: const Text(
              'Melhor combinação',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      gap(6),
      subheading(str(t['name'])),
      statLine('Objetivo', label(goals, t['goal'])),
      statLine('Calorias', '${number(t['calories'])} kcal por dia'),
      statLine('Duração', '${t['weeksCount']} semanas'),
      gap(8),
      Text(str(t['description']), style: const TextStyle(color: muted)),
      gap(),
      action('Usar este plano', changing ? null : () => useTemplate(t)),
    ],
  );
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      heading(
        'Planos alimentares',
        'Escolha um plano pronto para o seu objetivo ou crie o seu do zero.',
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: busy || changing ? null : create,
          child: const Text('Criar do zero'),
        ),
      ),
      gap(22),
      if (busy)
        loading()
      else if (error.isNotEmpty) ...[
        errorBox(error),
        action('Tentar novamente', load),
      ] else ...[
        if (profile['dailyCalories'] == null)
          Panel(
            children: [
              subheading('Preencha o seu perfil para ver planos sugeridos'),
              const Text(
                'Precisamos de peso, altura, idade, sexo, atividade e objetivo para calcular a sua meta diária.',
              ),
              gap(),
              for (final e in profileFields.entries)
                if (profile[e.key] == null || str(profile[e.key]).isEmpty)
                  statLine(e.value, 'Não informado'),
              gap(),
              action('Ir para o meu perfil', widget.goProfile),
            ],
          )
        else ...[
          subheading('Sugeridos para você'),
          Text(
            'Com base no seu objetivo (${label(goals, profile['goal'])}) e na sua meta de ${number(profile['dailyCalories'])} kcal por dia.',
            style: const TextStyle(color: muted),
          ),
          gap(),
          if (suggestionError.isNotEmpty)
            errorBox(suggestionError)
          else if (templates.isEmpty)
            const Text('Nenhum modelo disponível para este objetivo.')
          else
            LayoutBuilder(
              builder: (context, c) {
                final count = c.maxWidth >= 880
                    ? 3
                    : c.maxWidth >= 560
                    ? 2
                    : 1;
                final width = (c.maxWidth - 14 * (count - 1)) / count;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final t in templates)
                      SizedBox(width: width, child: templateCard(t)),
                  ],
                );
              },
            ),
          gap(8),
          const Text(
            'Sugestões de caráter informativo.',
            style: TextStyle(color: muted),
          ),
        ],
        gap(30),
        subheading('Meus planos'),
        Panel(
          children: [
            if (plans.isEmpty)
              const Text('Você ainda não tem planos alimentares.')
            else
              for (final p in plans) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            str(p['name']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '${label(goals, p['goal'])} · ${p['weeksCount']} semanas',
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: p['active'] == true ? yellow : Colors.white,
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        p['active'] == true ? 'Ativo' : 'Inativo',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  children: [
                    link('Abrir', changing ? null : () => showPlan(p['id'])),
                    link(
                      'Excluir',
                      changing ? null : () => remove(p),
                      destructive: true,
                    ),
                  ],
                ),
                const Divider(),
              ],
          ],
        ),
        gap(),
        link('Atualizar', changing ? null : load),
      ],
    ],
  );
}

class PlanFormPage extends StatefulWidget {
  final Session session;
  final Data initial;
  const PlanFormPage({super.key, required this.session, required this.initial});
  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, description;
  String? goal;
  bool active = false, busy = false;
  String error = '';
  bool get edit => widget.initial['id'] != null;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: str(widget.initial['name']));
    description = TextEditingController(
      text: str(widget.initial['description']),
    );
    goal = widget.initial['goal'] as String?;
    active = widget.initial['active'] == true;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final data = {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'goal': goal,
        'active': active,
      };
      final result = edit
          ? await widget.session.api.put(
              '/meal-plans/${widget.initial['id']}',
              data,
            )
          : await widget.session.api.post('/meal-plans', data);
      if (mounted) Navigator.pop(context, map(result));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: bar(context),
    body: PageBody(
      children: [
        heading(edit ? 'Editar plano' : 'Novo plano alimentar'),
        Panel(
          children: [
            errorBox(error),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field(name, 'Nome do plano', validate: requiredText),
                  dropdown(
                    'Objetivo',
                    goals,
                    goal,
                    (v) => setState(() => goal = v),
                    required: true,
                  ),
                  field(description, 'Descrição', maxLines: 3),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Plano ativo'),
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                  ),
                  gap(),
                  action(
                    busy ? 'Salvando…' : 'Salvar plano',
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
        ),
      ],
    ),
  );
}

class PlanPage extends StatefulWidget {
  final Session session;
  final dynamic id;
  const PlanPage({super.key, required this.session, required this.id});
  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  Data plan = {};
  bool busy = true;
  String error = '';
  int weekIndex = 0, dayIndex = 0;
  Api get api => widget.session.api;
  String get path => '/meal-plans/${widget.id}';
  @override
  void initState() {
    super.initState();
    load();
  }

  void apply(Data p) {
    plan = p;
    final weeks = rows(p['weeks']);
    if (weekIndex < 0 || weekIndex >= weeks.length) weekIndex = 0;
    final days = weeks.isEmpty ? <Data>[] : rows(weeks[weekIndex]['days']);
    if (dayIndex < 0 || dayIndex >= days.length) dayIndex = 0;
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final p = map(await api.get(path));
      if (mounted) setState(() => apply(p));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> changeWeek({Data? remove}) async {
    if (busy) return;
    if (remove != null &&
        !await confirm(
          context,
          'Excluir a semana ${remove['number']} e suas refeições?',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final result = map(
        await (remove == null
            ? api.post('$path/weeks')
            : api.delete('$path/weeks/${remove['id']}')),
      );
      if (mounted) {
        setState(() {
          if (remove == null) {
            weekIndex = rows(result['weeks']).length - 1;
          }
          dayIndex = 0;
          apply(result);
        });
      }
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editPlan() async {
    final result = await open<Data>(
      context,
      PlanFormPage(session: widget.session, initial: plan),
    );
    if (result != null && mounted) setState(() => apply(result));
  }

  Future<void> mealForm(Data week, Data day, [Data? meal]) async {
    final changed = await open<bool>(
      context,
      MealPage(
        session: widget.session,
        day: day,
        meal: meal,
        subtitle:
            '${plan['name']}, Semana ${week['number']}, ${dayName(day['weekday'])}.',
      ),
    );
    if (changed == true && mounted) await load();
  }

  Future<void> removeMeal(Data meal) async {
    if (!await confirm(context, 'Excluir ${meal['name']}?') || !mounted) return;
    setState(() => busy = true);
    try {
      await api.delete('/meals/${meal['id']}');
      if (mounted) await load();
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget dayPanel(Data week, Data day) => Panel(
    children: [
      subheading(dayName(day['weekday'])),
      Text('Semana ${week['number']}', style: const TextStyle(color: muted)),
      gap(8),
      action('Adicionar refeição', () => mealForm(week, day)),
      rule(),
      if (rows(day['meals']).isEmpty)
        const Text('Nenhuma refeição neste dia.'),
      for (final m in rows(day['meals'])) ...[
        stat(str(m['name']), nutrition(m, 'calorias', 'kcal')),
        Text(
          '${label(mealTypes, m['type'])} ${str(m['time'])}',
          style: const TextStyle(color: muted),
        ),
        for (final i in rows(m['ingredients'])) ...[
          statLine(
            '${map(i['food'])['name']}, ${number(i['quantity'])} ${i['unit']}',
            nutrition(i, 'calorias', 'kcal'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (c) => SimilarDialog(api: api, ingredient: i),
              ),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Tipos de opções'),
            ),
          ),
        ],
        Wrap(
          children: [
            link('Editar', () => mealForm(week, day, m)),
            link('Excluir', () => removeMeal(m), destructive: true),
          ],
        ),
        rule(),
      ],
      stat(
        'Total do dia',
        nutrition(day, 'calorias', 'kcal'),
        background: yellow,
      ),
      statLine('Proteínas', nutrition(day, 'proteinas', 'g')),
      statLine('Carboidratos', nutrition(day, 'carboidratos', 'g')),
      const Text(
        'Valores calculados pela API com base na TBCA.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
  Widget daySelector(List<Data> days) {
    if (MediaQuery.sizeOf(context).width < 790) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: i == dayIndex ? mint : Colors.white,
                    foregroundColor: ink,
                    side: BorderSide(color: i == dayIndex ? green : line),
                  ),
                  onPressed: () => setState(() => dayIndex = i),
                  child: Text(str(days[i]['weekday'])),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < days.length; i++) ...[
          Material(
            color: i == dayIndex ? mint : Colors.white,
            child: ListTile(
              dense: true,
              title: Text(
                str(days[i]['weekday']),
                style: TextStyle(
                  fontWeight: i == dayIndex ? FontWeight.w800 : FontWeight.w400,
                ),
              ),
              onTap: () => setState(() => dayIndex = i),
            ),
          ),
          const Divider(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = rows(plan['weeks']);
    final week = weeks.isEmpty ? <String, dynamic>{} : weeks[weekIndex];
    final days = rows(week['days']);
    final day = days.isEmpty ? <String, dynamic>{} : days[dayIndex];
    return Scaffold(
      appBar: bar(context),
      body: PageBody(
        children: [
          if (busy)
            loading()
          else if (error.isNotEmpty) ...[
            errorBox(error),
            action('Tentar novamente', load),
          ] else ...[
            heading(
              str(plan['name']),
              '${label(goals, plan['goal'])}. ${str(plan['description'])}',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: editPlan,
                  child: const Text('Editar plano'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Voltar aos planos'),
                ),
              ],
            ),
            gap(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < weeks.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: i == weekIndex ? mint : null,
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () => setState(() {
                          weekIndex = i;
                          dayIndex = 0;
                        }),
                        child: Text('Semana ${weeks[i]['number']}'),
                      ),
                    ),
                  link('Nova semana', () => changeWeek()),
                ],
              ),
            ),
            const Divider(),
            if (weeks.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: link(
                  'Excluir esta semana',
                  () => changeWeek(remove: week),
                  destructive: true,
                ),
              ),
            gap(10),
            if (days.isNotEmpty)
              NutriSplit(
                firstFlex: 2,
                secondFlex: 6,
                first: daySelector(days),
                second: dayPanel(week, day),
              )
            else
              const Text('Nenhuma semana disponível.'),
          ],
        ],
      ),
    );
  }
}
