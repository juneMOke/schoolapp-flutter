import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';

enum _TestMode { table, grid }

void main() {
  group('SegmentedTabFilter', () {
    testWidgets('affiche les options et notifie le changement', (tester) async {
      _TestMode selected = _TestMode.table;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SegmentedTabFilter<_TestMode>(
                  options: const [
                    SegmentedTabOption(
                      label: 'Tableau',
                      value: _TestMode.table,
                    ),
                    SegmentedTabOption(label: 'Grille', value: _TestMode.grid),
                  ],
                  selected: selected,
                  onSelected: (value) => setState(() => selected = value),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tableau'), findsOneWidget);
      expect(find.text('Grille'), findsOneWidget);

      await tester.tap(find.text('Grille'));
      await tester.pumpAndSettle();

      expect(selected, _TestMode.grid);
    });

    testWidgets('expose une semantique de groupe exclusif avec selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedTabFilter<_TestMode>(
              semanticsLabel: 'Bascule vue',
              options: const [
                SegmentedTabOption(label: 'Tableau', value: _TestMode.table),
                SegmentedTabOption(label: 'Grille', value: _TestMode.grid),
              ],
              selected: _TestMode.table,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final tableSemantics = tester.getSemantics(find.text('Tableau').first);
      final gridSemantics = tester.getSemantics(find.text('Grille').first);

      expect(
        tableSemantics,
        matchesSemantics(
          label: 'Tableau',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        gridSemantics,
        matchesSemantics(
          label: 'Grille',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
    });
  });
}
