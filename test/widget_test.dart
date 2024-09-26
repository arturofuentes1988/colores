// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importa el archivo main.dart de tu aplicación 'colores'.
import 'package:colores/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construye nuestra aplicación y desencadena un frame.
    await tester.pumpWidget(const MyApp());

    // Verifica que el contador comience en 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Encuentra el FloatingActionButton y simula un tap.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifica que el contador haya incrementado a 1.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
