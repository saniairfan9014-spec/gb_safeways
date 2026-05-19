import 'package:flutter_test/flutter_test.dart';
import 'package:gb_safeway_alert/app.dart';

void main() {
  testWidgets('App smoke test - boots successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app widget builds correctly
    expect(find.byType(MyApp), findsOneWidget);
  });
}
