import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/app.dart';

void main() {
  testWidgets('Fidelis app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FidelisApp());
    expect(find.text('FIDELIS'), findsWidgets);
  });
}