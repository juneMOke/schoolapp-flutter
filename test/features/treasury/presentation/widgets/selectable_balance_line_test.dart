import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/selectable_balance_line.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/treasury_balance_line.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

/// Toucher un point de la courbe : au doigt, on lit d'abord ; à la souris,
/// le clic ouvre (le survol a déjà montré l'infobulle).
void main() {
  late List<int> opened;

  const slots = [
    BalanceSlot(
      label: 'Lun. 19 oct.',
      balanceInCents: 400000,
      inflowsInCents: 50000,
      outflowsInCents: 0,
      partial: false,
    ),
    BalanceSlot(
      label: 'Mar. 20 oct.',
      balanceInCents: 450000,
      inflowsInCents: 50000,
      outflowsInCents: 0,
      partial: false,
    ),
    BalanceSlot(
      label: 'Mer. 21 oct.',
      balanceInCents: 481900,
      inflowsInCents: 31900,
      outflowsInCents: 0,
      partial: false,
    ),
  ];

  Future<void> pump(WidgetTester tester) async {
    setTestWindow(tester, const Size(800, 600));
    opened = [];
    await tester.pumpWidget(
      treasuryHost(
        SizedBox(
          width: 600,
          child: SelectableBalanceLine(
            height: 230,
            slots: slots,
            currency: TreasuryCurrency.usd,
            openingInCents: 400000,
            lineColor: Colors.blue,
            onOpenSlot: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Le milieu du dernier point : l'axe des montants réserve 74 dp à gauche.
  Offset lastPoint(WidgetTester tester) {
    final box = tester.getRect(find.byType(TreasuryBalanceLine));
    return Offset(box.right - 2, box.center.dy);
  }

  testWidgets('au doigt : le point choisi s affiche, rien ne s ouvre', (
    tester,
  ) async {
    await pump(tester);
    await tester.tapAt(lastPoint(tester));
    await tester.pumpAndSettle();
    expect(opened, isEmpty);
    expect(find.text('Ouvrir le rapport'), findsOneWidget);
    expect(
      find.textContaining('Mer. 21 oct.', findRichText: true),
      findsWidgets,
    );

    await tester.tap(find.text('Ouvrir le rapport'));
    expect(opened, [2]);
  });

  testWidgets('à la souris : le clic ouvre le rapport directement', (
    tester,
  ) async {
    await pump(tester);
    await tester.tapAt(lastPoint(tester), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(opened, [2]);
    expect(find.text('Ouvrir le rapport'), findsNothing);
  });
}
