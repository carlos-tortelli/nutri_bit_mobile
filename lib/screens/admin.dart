import 'package:flutter/material.dart';
import '../models/data.dart';
import '../services/api.dart';
import '../widgets/ui.dart';
import 'profile.dart';

class AdminHome extends StatelessWidget {
  final VoidCallback users, profiles;
  const AdminHome({super.key, required this.users, required this.profiles});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      heading('Painel administrativo', 'Escolha o que deseja gerenciar.'),
      Panel(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Usuários',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Cadastre e edite os usuários do sistema.'),
            trailing: link('Abrir', users),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Perfis',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Gerencie os perfis vinculados aos usuários.',
            ),
            trailing: link('Abrir', profiles),
          ),
        ],
      ),
    ],
  );
}

class AdminUsers extends StatefulWidget {
  final Session session;
  const AdminUsers({super.key, required this.session});
  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      search = TextEditingController();
  List<Data> users = [];
  Data? editing;
  bool busy = true, saving = false;
  String error = '';
  Api get api => widget.session.api;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in [name, email, password, search]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      users = rows(await api.get('/users'));
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  void clear() {
    editing = null;
    name.clear();
    email.clear();
    password.clear();
  }

  void edit(Data u) => setState(() {
    editing = u;
    name.text = str(u['name']);
    email.text = str(u['email']);
    password.clear();
  });
  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    setState(() {
      saving = true;
      error = '';
    });
    try {
      final data = {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'passwordHash': editing == null ? password.text : 'unchanged',
      };
      if (editing == null) {
        await api.post('/users', data);
      } else {
        await api.put('/users/${editing!['id']}', data);
      }
      if (mounted) {
        setState(clear);
        await load();
        if (mounted) toast(context, 'Usuário salvo.');
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(Data u) async {
    if (saving ||
        !await confirm(context, 'Excluir ${u['name']}?') ||
        !mounted) {
      return;
    }
    setState(() => saving = true);
    try {
      await api.delete('/users/${u['id']}');
      if (mounted) {
        if (editing?['id'] == u['id']) setState(clear);
        await load();
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.toLowerCase().trim();
    final filtered = users.where(
      (u) => '${u['name']} ${u['email']}'.toLowerCase().contains(query),
    );
    return PageBody(
      children: [
        heading(
          'Usuários',
          'Cadastre, visualize e edite os usuários do sistema.',
        ),
        errorBox(error),
        NutriSplit(
          firstFlex: 4,
          secondFlex: 6,
          first: Panel(
            children: [
              subheading(
                editing == null ? 'Novo usuário' : 'Editar usuário',
              ),
              Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    field(name, 'Nome', validate: (v) => requiredText(v, 3)),
                    field(
                      email,
                      'E-mail',
                      keyboard: TextInputType.emailAddress,
                      validate: (v) => (v ?? '').contains('@')
                          ? null
                          : 'E-mail inválido.',
                    ),
                    if (editing == null)
                      field(
                        password,
                        'Senha',
                        secret: true,
                        validate: (v) => requiredText(v, 6),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        action(
                          editing == null ? 'Cadastrar' : 'Salvar',
                          saving || busy ? null : save,
                        ),
                        OutlinedButton(
                          onPressed: saving ? null : () => setState(clear),
                          child: const Text('Limpar campos'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          second: Panel(
            children: [
              subheading('Usuários cadastrados'),
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Buscar por nome ou e-mail',
                ),
              ),
              gap(),
              if (busy)
                loading()
              else if (filtered.isEmpty)
                const Text('Nenhum usuário encontrado.')
              else
                for (final u in filtered) ...[
                  Row(
                    children: [
                      Avatar(str(u['name'])),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              str(u['name']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              str(u['email']),
                              style: const TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    children: [
                      link('Editar', saving ? null : () => edit(u)),
                      link(
                        'Excluir',
                        saving || u['id'] == widget.session.user?['sub']
                            ? null
                            : () => remove(u),
                        destructive: true,
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              link('Atualizar', saving || busy ? null : load),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminProfiles extends StatefulWidget {
  final Session session;
  const AdminProfiles({super.key, required this.session});
  @override
  State<AdminProfiles> createState() => _AdminProfilesState();
}

class _AdminProfilesState extends State<AdminProfiles> {
  List<Data> users = [], profiles = [];
  Data? editing;
  String? userId;
  final search = TextEditingController();
  bool busy = true, deleting = false;
  String error = '';
  int version = 0;
  Api get api => widget.session.api;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      users = rows(await api.get('/users'));
      profiles = rows(await api.get('/profiles'));
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  void clear() {
    editing = null;
    userId = null;
    version++;
  }

  Future<void> save(Data data) async {
    if (editing == null) {
      if (userId == null) throw Exception('Selecione um usuário.');
      await api.post('/profiles', {...data, 'userId': int.parse(userId!)});
    } else {
      await api.put('/profiles/${editing!['id']}', data);
    }
    if (mounted) {
      setState(clear);
      await load();
      if (mounted) toast(context, 'Perfil salvo.');
    }
  }

  Future<void> remove(Data p) async {
    if (deleting ||
        !await confirm(context, 'Excluir o perfil ${p['fullName']}?') ||
        !mounted) {
      return;
    }
    setState(() => deleting = true);
    try {
      await api.delete('/profiles/${p['id']}');
      if (mounted) {
        if (editing?['id'] == p['id']) setState(clear);
        await load();
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filtered = profiles.where(
      (p) => '${p['fullName']} ${map(p['user'])['email']}'
          .toLowerCase()
          .contains(query),
    );
    final assigned = profiles.map((p) => str(p['userId'])).toSet();
    final available = {
      for (final u in users)
        if (!assigned.contains(str(u['id'])))
          str(u['id']): '${u['name']} (${u['email']})',
    };
    final selectedUser = users.where((u) => str(u['id']) == userId).firstOrNull;
    return PageBody(
      children: [
        heading(
          'Perfis',
          'Cadastre, visualize e edite os perfis dos usuários.',
        ),
        errorBox(error),
        if (busy)
          loading()
        else
          NutriSplit(
            firstFlex: 4,
            secondFlex: 6,
            first: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (editing == null)
                  dropdown(
                    'Usuário',
                    available,
                    userId,
                    (v) => setState(() {
                      userId = v;
                      version++;
                    }),
                  )
                else
                  Text(
                    'Usuário: ${map(editing!['user'])['email'] ?? editing!['userId']}',
                  ),
                ProfileForm(
                  key: ValueKey(version),
                  initial: editing ?? {'fullName': selectedUser?['name']},
                  title: editing == null ? 'Novo perfil' : 'Editar perfil',
                  submit: editing == null
                      ? 'Cadastrar perfil'
                      : 'Salvar alterações',
                  cancel: () => setState(clear),
                  save: save,
                ),
              ],
            ),
            second: Panel(
              children: [
                subheading('Perfis cadastrados'),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Buscar por usuário ou nome',
                  ),
                ),
                gap(),
                if (filtered.isEmpty)
                  const Text('Nenhum perfil encontrado.')
                else
                  for (final p in filtered) ...[
                    Row(
                      children: [
                        Avatar(str(p['fullName']), str(p['avatarUrl'])),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                str(p['fullName']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(str(map(p['user'])['email'])),
                              Text(
                                '${number(p['weight'])} kg · ${number(p['height'])} cm · ${label(goals, p['goal'])}',
                                style: const TextStyle(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      children: [
                        link(
                          'Editar',
                          deleting
                              ? null
                              : () => setState(() {
                                  editing = p;
                                  userId = str(p['userId']);
                                  version++;
                                }),
                        ),
                        link(
                          'Excluir',
                          deleting ? null : () => remove(p),
                          destructive: true,
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                link('Atualizar', deleting ? null : load),
              ],
            ),
          ),
      ],
    );
  }
}
