import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_sleep_tracker/ui/design_system/circular_progress_ring.dart';

void main() {
  testWidgets('BentoConcentricRings handles NaN and Infinity gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BentoConcentricRings(
            calorieProgress: double.nan, // Simulating 0 / 0
            waterProgress: double.infinity, // Simulating 100 / 0
            caloriesLogged: 0,
            waterMlLogged: 100,
            waterTargetMl: 0,
          ),
        ),
      ),
    );

    expect(find.byType(BentoConcentricRings), findsOneWidget);
    // Should not throw an exception during layout or painting
    expect(tester.takeException(), isNull);
  });
}
