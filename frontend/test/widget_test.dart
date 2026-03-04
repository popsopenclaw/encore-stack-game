import 'package:encore_frontend/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with session gate or login', (tester) async {
    await tester.pumpWidget(const EncoreApp());
    await tester.pump(const Duration(milliseconds: 300));

    final hasGate = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasLogin = find.text('Login').evaluate().isNotEmpty;

    expect(hasGate || hasLogin, true);
  });
}
