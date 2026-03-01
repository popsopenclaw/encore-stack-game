import 'package:encore_frontend/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to login screen', (tester) async {
    await tester.pumpWidget(const EncoreApp());
    expect(find.text('Login'), findsOneWidget);
  });
}
