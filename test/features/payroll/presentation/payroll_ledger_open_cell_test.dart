import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_cells.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fin de ligne du livre : l'œil ouvre la fiche, le crayon (en brouillon)
/// les éléments variables.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onOpen,
    VoidCallback? onEdit,
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 96,
            child: PayrollLedgerOpenCell(onOpen: onOpen, onEdit: onEdit),
          ),
        ),
      ),
    ),
  );

  testWidgets('l œil ouvre la fiche, le crayon à côté', (tester) async {
    var opened = 0;
    var edited = 0;
    await pump(tester, onOpen: () => opened++, onEdit: () => edited++);

    final eye = find.byTooltip('Ouvrir la fiche de l\'agent');
    final pencil = find.byTooltip('Éléments variables');
    // L'icône fait 40 dp ; le bouton, sa zone d'appui, 48.
    final eyeButton = find.ancestor(of: eye, matching: find.byType(IconButton));
    expect(tester.getSize(eyeButton).width, greaterThanOrEqualTo(48));
    expect(tester.getCenter(eye).dx, lessThan(tester.getCenter(pencil).dx));

    await tester.tap(eye);
    await tester.tap(pencil);
    expect((opened, edited), (1, 1));
  });

  testWidgets('paie verrouillée : l œil seul', (tester) async {
    await pump(tester, onOpen: () {});
    expect(find.byTooltip('Ouvrir la fiche de l\'agent'), findsOneWidget);
    expect(find.byTooltip('Éléments variables'), findsNothing);
  });
}
