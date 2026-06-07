import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FacturationChargeDetailIntent _intent() => const FacturationChargeDetailIntent(
  chargeId: 'c1',
  studentId: 'stu-1',
  academicYearId: 'ay-1',
  firstName: 'Daniel',
  lastName: 'Kabongo',
  surname: 'Mwamba',
  levelName: '6e A',
  levelGroupName: 'Secondaire',
  feeCode: 'tuition',
  expectedAmountInCents: 30000,
  amountPaidInCents: 18000,
  currency: 'USD',
  chargeStatus: StudentChargeStatus.partial,
);

Future<void> _pump(WidgetTester tester, {required VoidCallback onPrint}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FacturationChargeDetailDialogView(
            intent: _intent(),
            allocations: const Text('ALLOC_SLOT'),
            onPrintStatements: onPrint,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'popin détail frais : en-tête, pastille statut, barre, clé/valeurs, pied',
    (tester) async {
      await _pump(tester, onPrint: () {});
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // En-tête sombre : sur-titre or-doux en MAJUSCULES.
      expect(find.text('DÉTAIL DU FRAIS'), findsOneWidget);
      // Pastille de statut de paiement.
      expect(find.text('Partiel'), findsOneWidget);
      // Barre de progression (même pattern que la ligne de frais).
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Lignes clé/valeur + montants visibles (attendu / payé / reste).
      expect(find.text('Montant attendu'), findsOneWidget);
      expect(find.text('Déjà payé'), findsOneWidget);
      expect(find.text('Reste à payer'), findsOneWidget);
      expect(find.textContaining('USD'), findsNWidgets(3));

      // Emplacement de la table « Paiements affectés ».
      expect(find.text('ALLOC_SLOT'), findsOneWidget);

      // Pied : impression / fermer.
      expect(find.text('Imprimer les relevés'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    },
  );

  testWidgets('« Imprimer les relevés » déclenche le callback', (tester) async {
    var printed = false;
    await _pump(tester, onPrint: () => printed = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Imprimer les relevés'));
    await tester.pump();

    expect(printed, isTrue);
  });

  testWidgets('rendu sans débordement en largeur mobile (320 dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, onPrint: () {});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Imprimer les relevés'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });
}
