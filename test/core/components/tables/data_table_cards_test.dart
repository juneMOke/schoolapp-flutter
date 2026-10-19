import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sur un téléphone, une table qui le demande passe en cartes : comprimées,
/// ses colonnes coupaient les montants.
void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    required double width,
    DataTablePhoneLayout layout = DataTablePhoneLayout.cards,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: DataTableView(
                  rows: [
                    DataTableRowSpec(
                      id: 'r1',
                      displayName: 'Kabeya Ada',
                      onTap: () => taps.add('r1'),
                      cells: const [
                        DataTableCellSpec(text: '19/10'),
                        DataTableCellSpec(text: 'Kabeya Ada'),
                        DataTableCellSpec(text: ''),
                        DataTableCellSpec(text: '1 250 000 CDF'),
                      ],
                    ),
                  ],
                  config: DataTableViewConfig(
                    phoneLayout: layout,
                    cardTitleColumn: 1,
                    columns: const [
                      DataTableColumnDef(label: 'Date', flex: 1),
                      DataTableColumnDef(label: 'Élève', flex: 2),
                      DataTableColumnDef(label: 'Source', flex: 1),
                      DataTableColumnDef(label: 'Montant', flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('téléphone : une carte titrée, chaque valeur nommée', (
    tester,
  ) async {
    final taps = await pump(tester, width: 360);

    expect(find.byType(DataTableHeader), findsNothing);
    expect(find.byType(DataTableCardItem), findsOneWidget);
    expect(find.text('Montant'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    // Une cellule vide ne s'affiche pas en tiret, et le titre pas deux fois.
    expect(find.text('Source'), findsNothing);
    expect(find.text('Élève'), findsNothing);
    expect(tester.getSize(find.text('1 250 000 CDF')).width, greaterThan(100));

    await tester.tap(find.text('Kabeya Ada'));
    expect(taps, ['r1']);
  });

  testWidgets('au-delà de 600 dp : la table', (tester) async {
    await pump(tester, width: 800);

    expect(find.byType(DataTableHeader), findsOneWidget);
    expect(find.byType(DataTableCardItem), findsNothing);
  });

  testWidgets('sans opt-in, la table reste une table', (tester) async {
    await pump(tester, width: 360, layout: DataTablePhoneLayout.table);

    expect(find.byType(DataTableCardItem), findsNothing);
  });
}
