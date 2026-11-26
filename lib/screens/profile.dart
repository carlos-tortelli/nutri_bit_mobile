import 'package:flutter/material.dart';
import '../models/data.dart';
import '../services/api.dart';
import '../widgets/ui.dart';

class ProfileForm extends StatefulWidget {
  final Data initial;
  final Future<void> Function(Data) save;
  final String title, submit;
  final VoidCallback? cancel;
  const ProfileForm({
    super.key,
    required this.initial,
    required this.save,
    this.title = 'Editar meus dados',
    this.submit = 'Salvar alterações',
    this.cancel,
  });
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, birth, weight, height, avatar;
  String? sex, activity, goal;
  bool busy = false;
  String error = '', preview = '';
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    name = TextEditingController(text: str(p['fullName']));
    birth = TextEditingController(text: str(p['birthDate']).split('T').first);
    weight = TextEditingController(text: str(p['weight']));
    height = TextEditingController(text: str(p['height']));
    avatar = TextEditingController(text: str(p['avatarUrl']));
    preview = avatar.text;
    sex = p['sex'] as String?;
    activity = p['activityLevel'] as String?;
    goal = p['goal'] as String?;
  }

  @override
  void dispose() {
    for (final c in [name, birth, weight, height, avatar]) {
      c.dispose();
    }
    super.dispose();
  }

  String? checkNumber(String? value, double min, double max) {
    if ((value ?? '').trim().isEmpty) return null;
    final n = decimal(value!);
    return n == null || !n.isFinite || n < min || n > max
        ? 'Informe um valor entre $min e $max.'
        : null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await widget.save({
        'fullName': name.text.trim(),
        'avatarUrl': avatar.text.trim(),
        if (birth.text.isNotEmpty) 'birthDate': birth.text,
        if (weight.text.isNotEmpty) 'weight': decimal(weight.text),
        if (height.text.isNotEmpty) 'height': decimal(height.text),
        if (sex != null) 'sex': sex,
        if (activity != null) 'activityLevel': activity,
        if (goal != null) 'goal': goal,
      });
      if (mounted) toast(context, 'Perfil salvo.');
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickDate() async {
    final today = DateTime.now();
    final min = DateTime(1900);
    final parsed = DateTime.tryParse(birth.text);
    final date = await showDatePicker(
      context: context,
      initialDate:
          parsed != null && !parsed.isBefore(min) && !parsed.isAfter(today)
          ? parsed
          : DateTime(today.year - 20),
      firstDate: min,
      lastDate: today,
    );
    if (date != null && mounted) {
      setState(() => birth.text = date.toIso8601String().split('T').first);
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
    children: [
      subheading(widget.title),
      errorBox(error),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Avatar(name.text, preview),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => preview = avatar.text.trim()),
                    child: const Text('Pré-visualizar'),
                  ),
                ),
              ],
            ),
            field(name, 'Nome completo', validate: requiredText),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: birth,
                readOnly: true,
                onTap: pickDate,
                decoration: const InputDecoration(
                  labelText: 'Data de nascimento',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
            NutriSplit(
              breakpoint: 310,
              first: field(
                weight,
                'Peso (kg)',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validate: (v) => checkNumber(v, 1, 500),
              ),
              second: field(
                height,
                'Altura (cm)',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validate: (v) => checkNumber(v, 30, 300),
              ),
            ),
            dropdown('Sexo', sexes, sex, (v) => setState(() => sex = v)),
            dropdown(
              'Nível de atividade',
              activities,
              activity,
              (v) => setState(() => activity = v),
            ),
            dropdown('Objetivo', goals, goal, (v) => setState(() => goal = v)),
            field(avatar, 'URL do avatar', keyboard: TextInputType.url),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                action(
                  busy ? 'Salvando…' : widget.submit,
                  busy ? null : save,
                ),
                if (widget.cancel != null)
                  OutlinedButton(
                    onPressed: busy ? null : widget.cancel,
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class ProfilePage extends StatefulWidget {
  final Session session;
  const ProfilePage({super.key, required this.session});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Data profile = {};
  bool busy = true;
  String error = '';
  int version = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      profile = map(await widget.session.api.get('/profiles/me'));
    } on ApiException catch (e) {
      if (e.status == 404) {
        profile = {'fullName': widget.session.user?['name']};
      } else {
        error = e.message;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) {
      setState(() {
        busy = false;
        version++;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      heading('Meu perfil'),
      if (busy)
        loading()
      else if (error.isNotEmpty) ...[
        errorBox(error),
        action('Tentar novamente', load),
      ] else
        NutriSplit(
          firstFlex: 4,
          secondFlex: 6,
          first: ProfileForm(
            key: ValueKey(version),
            initial: profile,
            cancel: () => setState(() => version++),
            save: (p) async {
              final result = map(
                await widget.session.api.put('/profiles/me', p),
              );
              if (mounted) setState(() => profile = result);
            },
          ),
          second: Panel(
            children: [
              Row(
                children: [
                  Avatar(str(profile['fullName']), str(profile['avatarUrl'])),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str(profile['fullName']),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          str(widget.session.user?['email']),
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              rule(),
              statLine(
                'Nome completo',
                str(profile['fullName'], 'Não informado'),
              ),
              statLine('E-mail', str(widget.session.user?['email'])),
              statLine('Data de nascimento', dateLabel(profile['birthDate'])),
              statLine(
                'Peso',
                profile['weight'] == null
                    ? 'Não informado'
                    : '${number(profile['weight'])} kg',
              ),
              statLine(
                'Altura',
                profile['height'] == null
                    ? 'Não informado'
                    : '${number(profile['height'])} cm',
              ),
              statLine('Sexo', label(sexes, profile['sex'])),
              statLine(
                'Nível de atividade',
                label(activities, profile['activityLevel']),
              ),
              statLine('Objetivo', label(goals, profile['goal'])),
              if (profile['dailyCalories'] != null)
                stat(
                  'Meta diária estimada',
                  '${number(profile['dailyCalories'])} kcal',
                  background: ink,
                )
              else
                const Text(
                  'Complete os dados para calcular sua meta diária.',
                  style: TextStyle(color: muted),
                ),
            ],
          ),
        ),
    ],
  );
}
