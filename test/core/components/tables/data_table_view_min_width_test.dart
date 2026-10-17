import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double? minWidth}) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: DataTableView(
                  rows: const [],
                  config: DataTableViewConfig(
                    columns: const [
                      DataTableColumnDef(label: 'Nom', flex: 1),
                      DataTableColumnDef(label: 'Prénom', flex: 1),
                    ],
                    minWidth: minWidth,
                    footer: const DataTableFooterConfig(label: 'pied'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('sans minWidth : rien ne défile', (tester) async {
    await pump(tester);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('sous minWidth : la table défile, le pied reste en place', (
    tester,
  ) async {
    await pump(tester, minWidth: 600);
    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    expect(
      find.descendant(of: scroll, matching: find.text('pied')),
      findsNothing,
    );
    expect(find.text('pied'), findsOneWidget);
  });
}
