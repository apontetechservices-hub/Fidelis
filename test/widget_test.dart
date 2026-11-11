import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/app.dart';

void main() {
  testWidgets('Fidelis app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FidelisApp());
    // The splash title renders as a calligraphic 'F' beside 'idelis' (the
    // Great Vibes + Cinzel Decorative split) — not one 'FIDELIS' text run.
    expect(find.text('F'), findsOneWidget);
    expect(find.text('idelis'), findsOneWidget);
    // Advance past the splash's 3.5s navigation timer: the app reaches
    // home and the test ends with no pending timers.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('F'), findsNothing);
  });
}
