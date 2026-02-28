import 'package:flutter_test/flutter_test.dart';
import 'package:encore_frontend/main.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const EncoreApp());
    expect(find.text('Encore! Companion'), findsOneWidget);
  });
}
