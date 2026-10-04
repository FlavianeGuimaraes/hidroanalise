import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hidroanalise/main.dart';

void main() {
  testWidgets('App abre e mostra a tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const HidroAnaliseApp());

    // Confirma que a tela inicial (Login) apareceu, sem travar.
    expect(find.text('HidroAnálise'), findsWidgets);
    expect(find.text('Acessar sistema'), findsOneWidget);
  });
}
