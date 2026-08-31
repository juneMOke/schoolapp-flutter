import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

Payment _payment({String? payerPhoneNumber = '+243816939060'}) => Payment(
  id: 'pay-1',
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  amounts: MoneyBag.of(const [Money(15000, 'USD')]),
  payerFirstName: 'Joseph',
  payerLastName: 'Kabongo',
  payerMiddleName: 'Mwamba',
  payerPhoneNumber: payerPhoneNumber,
  paidAt: DateTime(2025, 11, 8),
);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onTap,
  String? payerPhoneNumber = '+243816939060',
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FacturationPaymentLine(
          payment: _payment(payerPhoneNumber: payerPhoneNumber),
          onTap: onTap,
        ),
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

  testWidgets('le numéro du payeur s\'affiche sous son nom', (tester) async {
    await _pump(tester, onTap: () {});
    await tester.pumpAndSettle();

    expect(find.text('+243816939060'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
  });

  /// Tout versement antérieur au palier v28 — et tout versement encaissé sur
  /// un autre poste — n'a pas de numéro. Dans une LISTE, répéter « numéro
  /// inconnu » à chaque ligne ne renseigne personne et noie ce qui compte : la
  /// ligne disparaît, et le détail du versement, lui, le dit explicitement.
  testWidgets('sans numéro, la ligne disparaît au lieu de dire « inconnu »', (
    tester,
  ) async {
    await _pump(tester, onTap: () {}, payerPhoneNumber: null);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.textContaining('inconnu'), findsNothing);
  });
}
