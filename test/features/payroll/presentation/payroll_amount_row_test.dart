import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/sale_detail/boutique_sale_detail_parts.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';

/// Une ligne « libellé … montant » à 360 dp : un `Flexible` posé à côté d'un
/// `Expanded` partageait la place à parts égales — le libellé se repliait à
/// la moitié de la ligne même quand le montant était court.
void main() {
  const label = 'Retenue pour absence non justifiée du mois';

  Future<void> pump(WidgetTester tester, Widget row) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: row)),
        ),
      ),
    );
  }

  testWidgets('paie : le libellé prend la place que le montant laisse', (
    tester,
  ) async {
    await pump(tester, const PayrollAmountRow(label, '1 200 FC'));
    final width = tester.getSize(find.text(label)).width;
    expect(width, greaterThan(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fiche de vente : le libellé prend la place que la valeur '
      'laisse', (tester) async {
    await pump(
      tester,
      const BoutiqueSaleInfoRow(
        icon: Icons.person_outline,
        label: label,
        value: 'A. Mbala',
      ),
    );
    final width = tester.getSize(find.text(label)).width;
    // 320 − 16 (icône) − 8 : la moitié de ce reste valait ~148.
    expect(width, greaterThan(160));
    expect(tester.takeException(), isNull);
  });

  testWidgets('une valeur longue reste bornée à la moitié et ne déborde pas', (
    tester,
  ) async {
    await pump(
      tester,
      const PayrollAmountRow('Net', '1 234 567 890 123 456 789 012,00 FC'),
    );
    expect(
      tester.getSize(find.textContaining('1 234')).width,
      lessThanOrEqualTo(160),
    );
    expect(tester.takeException(), isNull);
  });
}
