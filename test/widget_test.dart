import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasky/main.dart';

void main() {
  testWidgets('Tasky UI Basic Elements Test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen()));
    expect(find.text('Tasky'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Tasky'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}