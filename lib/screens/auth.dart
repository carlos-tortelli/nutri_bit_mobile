import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/ui.dart';
import '../models/data.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback login, register;
  const WelcomePage({super.key, required this.login, required this.register});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: bar(context),
    body: PageBody(
      children: [
        NutriSplit(
          first: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading(
                'Planeje suas refeições, dia a dia.',
                'Monte planos alimentares por semana, dia e refeição. O Nutri-bit soma as calorias e os nutrientes de cada alimento e mostra quanto você pode comer por dia.',
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  action('Criar conta', register),
                  OutlinedButton(
                    onPressed: login,
                    child: const Text('Já tenho conta'),
                  ),
                ],
              ),
            ],
          ),
          second: Panel(
            children: [
              subheading('Seu dia no Nutri-bit'),
              const Text(
                'Exemplo de um dia planejado',
                style: TextStyle(color: muted),
              ),
              rule(),
              statLine('Café da manhã', '430 kcal'),
              statLine('Almoço', '680 kcal'),
              statLine('Lanche', '220 kcal'),
              statLine('Jantar', '540 kcal'),
              stat('Total do dia', '1.870 kcal', background: yellow),
              statLine('Proteínas', '98 g'),
              statLine('Carboidratos', '215 g'),
            ],
          ),
        ),
        gap(38),
        subheading('Como funciona'),
        rule(),
        for (final (i, title, description) in [
          (
            1,
            'Crie sua conta e preencha o perfil',
            'Informe peso, altura, idade, sexo e nível de atividade.',
          ),
          (
            2,
            'Monte o seu plano alimentar',
            'Organize semanas, dias e refeições.',
          ),
          (
            3,
            'Veja as calorias de cada dia',
            'Acompanhe calorias, proteínas e carboidratos.',
          ),
        ]) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(
              '$i',
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(description),
          ),
          const Divider(),
        ],
        gap(34),
        NutriSplit(
          first: heading('Uma meta diária feita para você'),
          second: Panel(
            children: [
              subheading('O que o Nutri-bit usa'),
              statLine('Peso', '80 kg'),
              statLine('Altura', '180 cm'),
              statLine('Idade', '25 anos'),
              statLine('Atividade', 'Moderada'),
              stat('Meta diária', '2.350 kcal', background: ink),
              const Text(
                'Valores ilustrativos',
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
        gap(28),
        Container(
          color: ink,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Text(
                'Comece a planejar hoje.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              gap(),
              action('Criar conta', register),
            ],
          ),
        ),
      ],
    ),
  );
}

class AuthPage extends StatefulWidget {
  final Session session;
  final bool registration;
  final VoidCallback back, switchMode;
  final void Function(bool) success;
  const AuthPage({
    super.key,
    required this.session,
    required this.registration,
    required this.back,
    required this.switchMode,
    required this.success,
  });
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  String error = '';
  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await widget.session.authenticate(
        email: email.text.trim(),
        password: password.text,
        name: widget.registration ? name.text.trim() : null,
      );
      if (mounted) widget.success(widget.registration);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Nutri-bit',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : widget.back,
          child: const Text('Voltar'),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: ink),
      ),
    ),
    body: PageBody(
      children: [
        gap(25),
        NutriSplit(
          first: heading(
            widget.registration ? 'Criar conta' : 'Entrar',
            widget.registration
                ? 'Leva menos de um minuto. Depois do cadastro, você já pode preencher o seu perfil.'
                : 'Acesse o seu perfil e os seus planos alimentares.',
          ),
          second: Panel(
            children: [
              errorBox(error),
              Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.registration)
                      field(name, 'Nome', validate: (v) => requiredText(v, 3)),
                    field(
                      email,
                      'E-mail',
                      keyboard: TextInputType.emailAddress,
                      validate: (v) => (v ?? '').contains('@')
                          ? null
                          : 'Informe um e-mail válido.',
                    ),
                    field(
                      password,
                      'Senha',
                      secret: true,
                      validate: (v) =>
                          (v ?? '').length < (widget.registration ? 6 : 1)
                          ? 'Informe a senha${widget.registration ? ' (mínimo de 6 caracteres)' : ''}.'
                          : null,
                    ),
                    action(
                      busy
                          ? 'Aguarde…'
                          : widget.registration
                          ? 'Criar conta'
                          : 'Entrar',
                      busy ? null : submit,
                      dark: !widget.registration,
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.registration
                              ? 'Já tem conta?'
                              : 'Não tem conta?',
                        ),
                        link(
                          widget.registration ? 'Entrar' : 'Criar conta',
                          busy ? null : widget.switchMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class GoalPage extends StatefulWidget {
  final Session session;
  final VoidCallback done;
  const GoalPage({super.key, required this.session, required this.done});
  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  String? selected;
  String error = '';
  bool busy = false;
  Future<void> save() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await widget.session.api.put('/profiles/me', {
        'fullName': widget.session.user!['name'],
        if (selected != null) 'goal': selected,
      });
      if (mounted) widget.done();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: bar(context, logout: widget.session.logout),
    body: PageBody(
      children: [
        NutriSplit(
          first: heading(
            'Qual é o seu objetivo?',
            'Vamos sugerir planos alimentares de acordo com ele. Você pode mudar depois no seu perfil.',
          ),
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              errorBox(error),
              for (final e in goals.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: selected == e.key ? yellow : Colors.white,
                    child: InkWell(
                      onTap: busy
                          ? null
                          : () => setState(() => selected = e.key),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: ink, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(goalDescriptions[e.key]!),
                            if (selected == e.key)
                              const Text(
                                'Selecionado',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              action(
                'Ver planos para mim',
                selected == null || busy ? null : save,
              ),
              link('Pular por enquanto', busy ? null : widget.done),
            ],
          ),
        ),
      ],
    ),
  );
}
