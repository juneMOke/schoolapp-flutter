import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un tableau se parcourt aux flèches : ↓ passe à la ligne suivante, Entrée
/// l'ouvre — sans une tabulation par ligne, ni l'œil de chacune.
void main() {
  testWidgets('↓ puis Entrée ouvre la deuxième ligne', (tester) async {
    final opened = <String>[];
    DataTableRowSpec row(String id) => DataTableRowSpec(
      id: id,
      displayName: id,
      cells: [DataTableCellSpec(text: id)],
      onTap: () => opened.add(id),
      trailing: DataTableTrailingSpec(
        type: DataTableTrailingType.eye,
        tooltip: 'Voir',
        onTap: () => opened.add('eye-$id'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DataTableView(
              rows: [row('a'), row('b'), row('c')],
              config: const DataTableViewConfig(
                columns: [DataTableColumnDef(label: 'Nom')],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, ['b']);
  });
}
