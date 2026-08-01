import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FacturationPaymentDetailIntent _intent({bool isPendingSync = false}) =>
    FacturationPaymentDetailIntent(
      paymentId: 'pay-1',
      studentId: 'stu-1',
      academicYearId: 'ay-1',
      firstName: 'Daniel',
      lastName: 'Kabongo',
      surname: 'Mwamba',
      levelName: '6e A',
      levelGroupName: 'Secondaire',
      payerFirstName: 'Joseph',
      payerLastName: 'Kabongo',
      payerMiddleName: 'Mwamba',
      amountInCents: 15000,
      currency: 'USD',
      paidAt: DateTime(2025, 11, 8),
      isPendingSync: isPendingSync,
    );

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onDownload,
  bool isPendingSync = false,
  String? receiptNumber,
  bool receiptPending = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FacturationPaymentDetailDialogView(
            intent: _intent(isPendingSync: isPendingSync),
            allocations: const Text('ALLOC_SLOT'),
            receiptNumber: receiptNumber,
            receiptPending: receiptPending,
            onDownloadReceipt: onDownload,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('popin détail paiement : montant, payeur, clé/valeurs, pied', (
    tester,
  ) async {
    await _pump(tester, onDownload: () {});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // En-tête sombre : sur-titre or-doux en MAJUSCULES + montant (titre).
    expect(find.text('DÉTAIL DU PAIEMENT'), findsOneWidget);
    expect(find.textContaining('150'), findsWidgets);

    // En-tête payeur (personne) ≠ élève.
    expect(find.text('Payeur'), findsOneWidget);
    expect(find.text('Kabongo Mwamba Joseph'), findsOneWidget);

    // Lignes clé/valeur (chacune sur sa ligne).
    expect(find.text('Montant versé'), findsOneWidget);
    expect(find.text('Date de paiement'), findsOneWidget);
    expect(find.text('Moyen de paiement'), findsOneWidget);
    expect(find.text('Espèces'), findsOneWidget);
    expect(find.text('Encaissé par'), findsOneWidget);
    expect(find.text('Élève'), findsOneWidget);
    expect(find.text('Kabongo Mwamba Daniel'), findsOneWidget);
    expect(find.text('Reçu n°'), findsOneWidget);
    // Valeurs vides (Encaissé par / Reçu n°) → tiret.
    expect(find.text('—'), findsNWidgets(2));

    // Emplacement de la répartition par frais.
    expect(find.text('ALLOC_SLOT'), findsOneWidget);

    // Pied : télécharger le reçu / fermer.
    expect(find.text('Télécharger le reçu'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('« Télécharger le reçu » déclenche le callback', (tester) async {
    var downloaded = false;
    await _pump(tester, onDownload: () => downloaded = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Télécharger le reçu'));
    await tester.pump();

    expect(downloaded, isTrue);
  });

  // Le serveur produit le reçu à partir de l'identifiant du paiement. Tant que
  // l'encaissement n'est pas remonté, cet identifiant est un uuid client qu'il
  // ne connaît pas : l'action ne peut qu'échouer en 404.
  testWidgets('paiement non synchronisé : action éteinte et expliquée', (
    tester,
  ) async {
    await _pump(tester, onDownload: null, isPendingSync: true);
    await tester.pumpAndSettle();

    expect(find.text('Télécharger le reçu'), findsOneWidget);
    expect(
      find.text('Le reçu sera disponible une fois le paiement synchronisé.'),
      findsOneWidget,
    );

    // Le bouton reste visible mais inerte.
    await tester.tap(find.text('Télécharger le reçu'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('paiement synchronisé : aucune explication d attente', (
    tester,
  ) async {
    await _pump(tester, onDownload: () {});
    await tester.pumpAndSettle();

    expect(
      find.text('Le reçu sera disponible une fois le paiement synchronisé.'),
      findsNothing,
    );
  });

  group('ligne « Reçu n° »', () {
    testWidgets('affiche le numéro définitif quand il est connu', (
      tester,
    ) async {
      await _pump(
        tester,
        onDownload: () {},
        receiptNumber: 'ETL-RC-2526-000212',
      );
      await tester.pumpAndSettle();

      expect(find.text('ETL-RC-2526-000212'), findsOneWidget);
      // Seule « Encaissé par » reste vide.
      expect(find.text('—'), findsOneWidget);
    });

    // Un `PROV-…` local n'est pas un numéro de pièce : l'afficher comme tel
    // ferait passer un provisoire pour une référence officielle.
    testWidgets('annonce l attente plutôt qu un numéro provisoire', (
      tester,
    ) async {
      await _pump(tester, onDownload: () {}, receiptPending: true);
      await tester.pumpAndSettle();

      expect(find.text('En attente de synchronisation'), findsOneWidget);
    });

    testWidgets('reste vide quand rien n est connu', (tester) async {
      await _pump(tester, onDownload: () {});
      await tester.pumpAndSettle();

      expect(find.text('En attente de synchronisation'), findsNothing);
      expect(find.text('—'), findsNWidgets(2));
    });
  });

  testWidgets('rendu sans débordement en largeur mobile (320 dp)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, onDownload: () {});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Les deux actions du pied restent présentes (empilées sur mobile).
    expect(find.text('Télécharger le reçu'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });
}
