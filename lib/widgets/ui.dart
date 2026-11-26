import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

const ink = Color(0xff16261d),
    green = Color(0xff3aa76d),
    mint = Color(0xffe6f4ec),
    yellow = Color(0xfff2c230),
    muted = Color(0xff5b6b61),
    line = Color(0xffcbd5ce),
    danger = Color(0xffb3261e);
ThemeData nutriTheme({bool useArchivo = true}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      primary: green,
      surface: Colors.white,
      error: danger,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme:
        (useArchivo
                ? GoogleFonts.archivoTextTheme(base.textTheme)
                : base.textTheme)
            .apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarThemeData(
      backgroundColor: Colors.white,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: ink, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: ink, width: 2),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: green, width: 2),
      ),
      labelStyle: TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: ink, width: 2),
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(0, 46),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xff23794b),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
  );
}

class Panel extends StatelessWidget {
  final List<Widget> children;
  const Panel({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: ink, width: 9),
        bottom: BorderSide(color: ink, width: 2),
        left: BorderSide(color: ink, width: 2),
        right: BorderSide(color: ink, width: 2),
      ),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class NutriSplit extends StatelessWidget {
  final Widget first, second;
  final int firstFlex, secondFlex;
  final double breakpoint;
  const NutriSplit({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.breakpoint = 750,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth >= breakpoint
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: firstFlex, child: first),
              const SizedBox(width: 22),
              Expanded(flex: secondFlex, child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 22), second],
          ),
  );
}

Widget heading(String title, [String subtitle = '']) => Padding(
  padding: const EdgeInsets.only(bottom: 22),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.05,
        ),
      ),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 9),
        Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 15, height: 1.4),
        ),
      ],
    ],
  ),
);
Widget subheading(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
  ),
);
Widget gap([double size = 14]) => SizedBox(height: size);
Widget rule() => const Divider(color: ink, thickness: 4, height: 16);
Widget stat(String title, String value, {Color? background}) => Container(
  color: background,
  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5),
  child: Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: background == null ? FontWeight.w400 : FontWeight.w800,
            color: background == ink ? Colors.white : ink,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: background == ink ? Colors.white : ink,
          ),
        ),
      ),
    ],
  ),
);
Widget statLine(String title, String value) =>
    Column(children: [stat(title, value), const Divider()]);
Widget action(String title, VoidCallback? onPressed, {bool dark = false}) =>
    FilledButton(
      style: dark ? FilledButton.styleFrom(backgroundColor: ink) : null,
      onPressed: onPressed,
      child: Text(title),
    );
Widget link(
  String title,
  VoidCallback? onPressed, {
  bool destructive = false,
}) => TextButton(
  onPressed: onPressed,
  style: destructive ? TextButton.styleFrom(foregroundColor: danger) : null,
  child: Text(title),
);
Widget field(
  TextEditingController controller,
  String title, {
  bool secret = false,
  TextInputType? keyboard,
  String? hint,
  String? Function(String?)? validate,
  int maxLines = 1,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: TextFormField(
    controller: controller,
    obscureText: secret,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: title, hintText: hint),
    validator: validate,
  ),
);
Widget dropdown(
  String title,
  Map<String, String> options,
  String? value,
  ValueChanged<String?> changed, {
  bool required = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: DropdownButtonFormField<String>(
    initialValue: options.containsKey(value) ? value : null,
    isExpanded: true,
    decoration: InputDecoration(labelText: title),
    items: options.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: changed,
    validator: required
        ? (v) => v == null ? 'Selecione uma opção.' : null
        : null,
  ),
);
String? requiredText(String? s, [int min = 2]) => (s?.trim().length ?? 0) < min
    ? 'Informe pelo menos $min caracteres.'
    : null;
Widget errorBox(String message) => message.isEmpty
    ? const SizedBox.shrink()
    : Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: danger)),
        child: Text(message, style: const TextStyle(color: danger)),
      );
void toast(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Text('Confirmar exclusão'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Excluir', style: TextStyle(color: danger)),
          ),
        ],
      ),
    ) ??
    false;
Future<T?> open<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));
PreferredSizeWidget bar(
  BuildContext context, {
  String title = 'Nutri-bit',
  VoidCallback? logout,
}) => AppBar(
  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
  actions: [
    if (logout != null)
      TextButton(onPressed: logout, child: const Text('Sair')),
    const SizedBox(width: 10),
  ],
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(color: ink),
  ),
);

class Avatar extends StatelessWidget {
  final String name, url;
  const Avatar(this.name, [this.url = '', Key? key]) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
    final fallback = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
    return ClipOval(
      child: Container(
        width: 58,
        height: 58,
        color: mint,
        child: url.startsWith('https://') || url.startsWith('http://')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

Widget loading() => const Center(
  child: Padding(
    padding: EdgeInsets.all(28),
    child: CircularProgressIndicator(),
  ),
);
String nutrition(Data data, String key, String unit) =>
    '${number(data[key])} $unit';
