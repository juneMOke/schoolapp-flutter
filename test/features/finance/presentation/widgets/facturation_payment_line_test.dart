import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

Payment _payment({String? receiptNumber}) => Payment(
  id: 'pay-1',
  receiptNumber: receiptNumber,
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  amounts: MoneyBag.of(const [Money(15000, 'USD')]),
  payerFirstName: 'Joseph',
  payerLastName: 'Kabongo',
  payerMiddleName: 'Mwamba',
  payerPhoneNumber: '+243816939060',
  paidAt: DateTime(2025, 11, 8),
);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onTap,
  String? receiptNumber = 'CF-RC-2627-000802',
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationPaymentLine(
          payment: _payment(receiptNumber: receiptNumber),
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ligne de versement : reçu, médaillon, montant « + », méta Espèces',
    (tester) async {
      await _pump(tester, onTap: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      expect(find.text('CF-RC-2627-000802'), findsOneWidget);
      // Médaillon billet + chevron.
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      // Montant préfixé « + » + devise. Le `+ ` avec son espace, jamais le `+`
      // nu : depuis que la ligne porte aussi le numéro du payeur, un `+` seul
      // matche `+243816939060` autant que le montant.
      expect(find.textContaining('+ '), findsOneWidget);
      // Le dollar s'abrège « $ ».
      expect(find.textContaining(r'$'), findsOneWidget);
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

  // Le numéro du reçu, pas le payeur : c'est lui que la famille a sur son
  // papier. Le payeur et son téléphone se lisent dans le détail.
  testWidgets('sans numéro définitif, la ligne le dit', (tester) async {
    await _pump(tester, onTap: () {}, receiptNumber: null);
    await tester.pumpAndSettle();

    expect(find.text('Reçu en attente de numéro'), findsOneWidget);
    expect(find.text('Kabongo Mwamba Joseph'), findsNothing);
  });

  testWidgets('ni le payeur ni son téléphone sur la ligne', (tester) async {
    await _pump(tester, onTap: () {});
    await tester.pumpAndSettle();

    expect(find.text('+243816939060'), findsNothing);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
  });
}
