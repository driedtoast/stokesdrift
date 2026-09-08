import 'package:flutter_test/flutter_test.dart';
import 'package:stokedrift/main.dart';

void main() {
  testWidgets('App renders splash screen then home', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const StokesdriftApp());

    // Splash screen should show the brand name
    expect(find.text('stokesdrift'), findsOneWidget);
  });
}