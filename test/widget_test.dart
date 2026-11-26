import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_bit_mobile/screens/auth.dart';
import 'package:nutri_bit_mobile/widgets/ui.dart';

void main() {
  testWidgets('Apresentação mostra as ações de cadastro e login', (
    tester,
  ) async {
    var login = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: nutriTheme(useArchivo: false),
        home: WelcomePage(login: () => login = true, register: () {}),
      ),
    );
    expect(find.text('Planeje suas refeições, dia a dia.'), findsOneWidget);
    await tester.ensureVisible(find.text('Já tenho conta'));
    await tester.tap(find.text('Já tenho conta'));
    expect(login, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Painel responsivo em tela pequena', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: nutriTheme(useArchivo: false),
        home: WelcomePage(login: () {}, register: () {}),
      ),
    );
    expect(find.text('Criar conta'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
