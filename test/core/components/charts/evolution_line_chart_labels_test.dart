import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/evolution_line_chart.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';

/// Sur un téléphone, une étiquette d'abscisse sur quelques-unes — et chacune
/// une seule fois, le point mis en avant compris.
void main() {
  Future<List<String>> labelsShown(WidgetTester tester, int count) async {
    final points = [
      for (var i = 0; i < count; i++)
        LineChartPoint(
          label: 'L$i',
          value: (i % 5).toDouble() + 1,
          isHighlighted: i == count - 1,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: EvolutionLineChart(
                points: points,
                lineColor: Colors.blue,
                highlightColor: Colors.orange,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return [
      for (var i = 0; i < count; i++)
        if (find.text('L$i').evaluate().isNotEmpty) 'L$i',
    ];
  }

  testWidgets('vingt points sur 300 dp : un pas régulier, pas deux', (
    tester,
  ) async {
    final shown = await labelsShown(tester, 20);

    expect(shown.length, greaterThanOrEqualTo(4));
    expect(shown, contains('L19'));
    // Ses voisins trop proches s'effacent devant le point mis en avant.
    expect(shown, isNot(contains('L18')));
  });

  testWidgets('chaque étiquette une seule fois', (tester) async {
    await labelsShown(tester, 7);
    for (var i = 0; i < 7; i++) {
      expect(find.text('L$i').evaluate().length, lessThanOrEqualTo(1));
    }
  });
}
