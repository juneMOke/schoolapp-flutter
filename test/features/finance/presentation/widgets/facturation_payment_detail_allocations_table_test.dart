import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_allocations_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _allocations = <PaymentAllocation>[
  PaymentAllocation(
    id: 'a1',
    paymentId: 'p1',
    studentChargeId: 'c1',
    feeCode: 'tuition',
    studentChargeLabel: 'Frais de scolarité',
    amountInCents: 12000,
    currency: 'USD',
  ),
  PaymentAllocation(
    id: 'a2',
    paymentId: 'p1',
    studentChargeId: 'c2',
    feeCode: 'supplies',
    studentChargeLabel: 'Fournitures',
    amountInCents: 3000,
    currency: 'USD',
  ),
];

Future<void> _pump(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      locale: Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          // Largeur étroite, comme dans la popin de détail d'un paiement.
          child: SizedBox(
            width: 460,
            child: FacturationPaymentDetailAllocationsTable(
              allocations: _allocations,
              totalInCents: 15000,
              currency: 'USD',
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche un montant par allocation + total (3 montants)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 2 allocations + 1 total = 3 montants.
    expect(find.textContaining('USD'), findsNWidgets(3));
  });

  testWidgets(
    'le montant total reste dans la largeur visible (pas hors-écran)',
    (tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      final tableRect = tester.getRect(
        find.byType(FacturationPaymentDetailAllocationsTable),
      );
      final totalAmount = find.textContaining('150');
      expect(totalAmount, findsOneWidget);
      expect(
        tester.getRect(totalAmount).right,
        lessThanOrEqualTo(tableRect.right + 1),
      );
    },
  );
}
