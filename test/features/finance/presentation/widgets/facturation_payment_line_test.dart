import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Payment _payment() => Payment(
  id: 'pay-1',
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  amountInCents: 15000,
  currency: 'USD',
  payerFirstName: 'Joseph',
  payerLastName: 'Kabongo',
  payerMiddleName: 'Mwamba',
  paidAt: DateTime(2025, 11, 8),
);

Future<void> _pump(WidgetTester tester, {required VoidCallback onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationPaymentLine(payment: _payment(), onTap: onTap),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ligne de versement : payeur, médaillon, montant « + », méta Espèces',
    (tester) async {
      await _pump(tester, onTap: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Payeur « Nom Post-nom Prénom » (personne, pas l'élève).
      expect(find.text('Kabongo Mwamba Joseph'), findsOneWidget);
      // Médaillon billet + chevron.
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      // Montant préfixé « + » + devise.
      expect(find.textContaining('+'), findsOneWidget);
      expect(find.textContaining('USD'), findsOneWidget);
      // Méta : moyen toujours « Espèces ».
      expect(find.textContaining('Espèces'), findsOneWidget);
    },
  );

  testWidgets('le clic remonte onTap (ouvre le détail du paiement)', (
    tester,
  ) async {
    var tapped = false;
    await _pump(tester, onTap: () => tapped = true);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FacturationPaymentLine));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
