import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edushieldup/main.dart';

void main() {
  testWidgets('EduShield app smoke test', (WidgetTester tester) async {
    // Budujemy naszą główną aplikację
    await tester.pumpWidget(const MyApp());

    // Sprawdzamy, czy aplikacja poprawnie się renderuje
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
