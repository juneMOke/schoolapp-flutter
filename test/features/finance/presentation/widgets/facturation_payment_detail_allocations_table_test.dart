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
              // Le total se dérive des lignes, et chacune porte SA devise :
              // la table recevait une devise unique pour toute la répartition.
              allocations: _allocations,
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
    // Le dollar s'abrège « $ ».
    expect(find.textContaining(r'$'), findsNWidgets(3));
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

  /// La table nommait la NATURE de chaque imputation. Deux versements sur deux
  /// tranches d'un même minerval s'y lisaient à l'identique — et c'est le seul
  /// écran qui dit ce que le guichet a réellement encaissé.
  group('la répartition nomme la tranche', () {
    testWidgets('libellé gelé + code de la tranche', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 460,
                child: FacturationPaymentDetailAllocationsTable(
                  allocations: [
                    PaymentAllocation(
                      id: 'a1',
                      paymentId: 'p1',
                      studentChargeId: 'c1',
                      feeCode: 'EXAMINATION',
                      studentChargeLabel: 'Organisation matériel examens — 2/3',
                      feeTariffCode: 'OM2',
                      amountInCents: 500000,
                      currency: 'CDF',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Organisation matériel examens — 2/3 (OM2)'),
        findsOneWidget,
      );
    });

    /// Le libellé est celui GELÉ à l'encaissement, pas une nature relocalisée :
    /// « Fournitures » est ce que le guichet a validé, et le papier remis à la
    /// famille dit la même chose. La nature `supplies` n'a d'ailleurs pas de
    /// traduction — elle retombait sur « Frais scolaire ».
    testWidgets('sans code, le libellé gelé prime sur la nature', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('Fournitures'), findsOneWidget);
      expect(find.text('Frais de scolarité'), findsOneWidget);
    });
  });
}
