import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

Future<void> _pump(WidgetTester tester, List<EteeloBarRow> rows) async {
  await tester.pumpWidget(
    const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: SizedBox.shrink(),
    ),
  );
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 500, child: EteeloBarRows(rows: rows)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EteeloBarRow _row(
  String label,
  int value, {
  VoidCallback? onTap,
  Color color = AppColors.bleuArdoise,
}) => EteeloBarRow(
  label: label,
  value: value,
  valueLabel: '$value',
  color: color,
  onTap: onTap,
);

void main() {
  testWidgets('chaque ligne écrit son libellé et sa valeur', (tester) async {
    await _pump(tester, [_row('6e année', 84), _row('5e année', 61)]);

    expect(find.text('6e année'), findsOneWidget);
    expect(find.text('84'), findsOneWidget);
    expect(find.text('5e année'), findsOneWidget);
    expect(find.text('61'), findsOneWidget);
  });

  testWidgets('la barre occupe sa part du TOTAL, pas du maximum', (
    tester,
  ) async {
    // 50 / (50 + 150) = 25 % : une lecture en part du maximum donnerait 33 %.
    await _pump(tester, [_row('A', 50), _row('B', 150)]);

    final factors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.widthFactor)
        .toList();

    expect(factors, hasLength(2));
    expect(factors[0], closeTo(0.25, 0.001));
    expect(factors[1], closeTo(0.75, 0.001));
  });

  testWidgets('un total nul ne divise pas par zéro', (tester) async {
    await _pump(tester, [_row('A', 0), _row('B', 0)]);

    expect(tester.takeException(), isNull);
    final factors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.widthFactor);
    expect(factors, everyElement(0.0));
  });

  testWidgets('sans onTap la ligne ne promet aucun geste', (tester) async {
    await _pump(tester, [_row('A', 10)]);

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('avec onTap la ligne est cliquable et annoncée comme bouton', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, [_row('6e année', 84, onTap: () => taps++)]);

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byType(InkWell));
    expect(taps, 1);

    expect(
      tester.getSemantics(find.bySemanticsLabel('6e année, 84')),
      matchesSemantics(
        label: '6e année, 84',
        isButton: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('le libellé long est tronqué, il ne pousse pas la barre', (
    tester,
  ) async {
    await _pump(tester, [
      _row('Première année de l\'enseignement secondaire général', 12),
    ]);

    final label = tester.widget<Text>(
      find.text('Première année de l\'enseignement secondaire général'),
    );
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.maxLines, 1);
  });
}
