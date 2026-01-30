import 'package:flutter_test/flutter_test.dart';
import 'package:smart_water_app/main.dart';

void main() {
  testWidgets('App starts and shows navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartWaterApp());
    await tester.pumpAndSettle();

    // Verify navigation bar is present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Can navigate between tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartWaterApp());
    await tester.pumpAndSettle();

    // Tap on Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    // Verify Analytics screen title
    expect(find.text('Water Analytics'), findsOneWidget);

    // Tap on Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify Settings content appears
    expect(find.text('Dark Mode'), findsOneWidget);
  });
}
