import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/api.dart';
import 'widgets/ui.dart';
import 'screens/auth.dart';
import 'screens/profile.dart';
import 'screens/plans.dart';
import 'screens/admin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriBitApp());
}

class NutriBitApp extends StatefulWidget {
  const NutriBitApp({super.key});
  @override
  State<NutriBitApp> createState() => _NutriBitAppState();
}

class _NutriBitAppState extends State<NutriBitApp> {
  late final Session session;
  final nav = GlobalKey<NavigatorState>();
  String stage = 'welcome';
  @override
  void initState() {
    super.initState();
    session = Session(Api());
    session.addListener(sessionChanged);
  }

  void sessionChanged() {
    if (!session.loggedIn) {
      nav.currentState?.popUntil((r) => r.isFirst);
      if (mounted) setState(() => stage = 'login');
    }
  }

  @override
  void dispose() {
    session.removeListener(sessionChanged);
    session.dispose();
    super.dispose();
  }

  void go(String value) {
    if (mounted) setState(() => stage = value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: nav,
    title: 'Nutri-bit',
    debugShowCheckedModeBanner: false,
    theme: nutriTheme(useArchivo: !const bool.fromEnvironment('OFFLINE_FONT')),
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: switch (stage) {
      'login' || 'register' => AuthPage(
        key: ValueKey(stage),
        session: session,
        registration: stage == 'register',
        back: () => go('welcome'),
        switchMode: () => go(stage == 'login' ? 'register' : 'login'),
        success: (registered) =>
            go(registered && !session.admin ? 'goal' : 'home'),
      ),
      'goal' when session.loggedIn => GoalPage(
        session: session,
        done: () => go('home'),
      ),
      'home' when session.loggedIn => HomePage(session: session),
      _ => WelcomePage(
        login: () => go('login'),
        register: () => go('register'),
      ),
    },
  );
}

class HomePage extends StatefulWidget {
  final Session session;
  const HomePage({super.key, required this.session});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  @override
  void initState() {
    super.initState();
    index = widget.session.admin ? 0 : 1;
  }

  void select(int i) => setState(() => index = i);
  @override
  Widget build(BuildContext context) {
    final admin = widget.session.admin;
    final labels = admin
        ? ['Início', 'Usuários', 'Perfis']
        : ['Meu perfil', 'Planos alimentares'];
    final icons = admin
        ? [Icons.dashboard_outlined, Icons.people_outline, Icons.badge_outlined]
        : [Icons.person_outline, Icons.restaurant_menu];
    final page = admin
        ? (index == 0
              ? AdminHome(users: () => select(1), profiles: () => select(2))
              : index == 1
              ? AdminUsers(session: widget.session)
              : AdminProfiles(session: widget.session))
        : (index == 0
              ? ProfilePage(session: widget.session)
              : PlansPage(session: widget.session, goProfile: () => select(0)));
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Nutri-bit',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            if (wide) ...[
              const SizedBox(width: 24),
              for (var i = 0; i < labels.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index ? green : Colors.transparent,
                        width: 4,
                      ),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => select(i),
                    child: Text(labels[i], style: const TextStyle(color: ink)),
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.session.logout,
            child: const Text('Sair'),
          ),
          const SizedBox(width: 10),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: ink),
        ),
      ),
      body: SafeArea(child: page),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: mint,
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
    );
  }
}
