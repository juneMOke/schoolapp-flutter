import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FacturationPaymentDetailIntent _intent({
  bool isPendingSync = false,
  String? cashierFullName,
}) => FacturationPaymentDetailIntent(
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
  cashierFullName: cashierFullName,
);

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback? onDownload,
  bool isPendingSync = false,
  String? receiptNumber,
  bool receiptPending = false,
  EditiqueCacheEntry? cancelledReceipt,
  String? cashierFullName,
  Widget? ticketPrint,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FacturationPaymentDetailDialogView(
            intent: _intent(
              isPendingSync: isPendingSync,
              cashierFullName: cashierFullName,
            ),
            allocations: const Text('ALLOC_SLOT'),
            receiptNumber: receiptNumber,
            receiptPending: receiptPending,
            onDownloadReceipt: onDownload,
            cancelledReceipt: cancelledReceipt,
            ticketPrint: ticketPrint,
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
    // Deux tirets : « Encaissé par » et « Reçu n° ». Le premier est un état
    // NORMAL — le nom n'est stampé que par le poste qui encaisse, et aucun
    // contrat de synchronisation ne le descend depuis un autre guichet.
    expect(find.text('—'), findsNWidgets(2));

    // Emplacement de la répartition par frais.
    expect(find.text('ALLOC_SLOT'), findsOneWidget);

    // Pied : télécharger le reçu / fermer.
    expect(find.text('Télécharger le reçu'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  /// Le nom vient des colonnes stampées à l'encaissement (v19). Il traverse
  /// désormais toute la chaîne : le DAO les lisait déjà, mais le mapper vers
  /// l'entité `Payment` les jetait — le guichet voyait un tiret sur une donnée
  /// présente en base.
  testWidgets('nomme l encaisseur quand le poste l a stampé', (tester) async {
    await _pump(tester, onDownload: () {}, cashierFullName: 'Jean Kabeya');
    await tester.pumpAndSettle();

    expect(find.text('Jean Kabeya'), findsOneWidget);
    // Un seul tiret restant : « Reçu n° ». La ligne de l'encaisseur est servie.
    expect(find.text('—'), findsOneWidget);
  });

  /// Le rattrapage n'est offert que sur un versement dont AUCUN papier n'est
  /// sorti. La modale ne juge que la dernière des trois conditions — le reçu
  /// annulé —, les deux autres étant métier et tenues par le repository. Un
  /// reçu retiré ne doit jamais ressortir sous forme de ticket.
  group('rattrapage d\'impression', () {
    testWidgets('la ligne prend place sous la répartition', (tester) async {
      await _pump(
        tester,
        onDownload: () {},
        ticketPrint: const Text('TICKET_SLOT'),
      );
      await tester.pumpAndSettle();

      expect(find.text('TICKET_SLOT'), findsOneWidget);
    });

    testWidgets('rien du tout quand le versement a déjà son papier', (
      tester,
    ) async {
      await _pump(tester, onDownload: () {});
      await tester.pumpAndSettle();

      expect(find.text('TICKET_SLOT'), findsNothing);
    });
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
    // En production, `receiptPending` dérive de `isPendingSync` : les dissocier
    // ici testerait une combinaison qui n'existe pas.
    await _pump(
      tester,
      onDownload: null,
      isPendingSync: true,
      receiptPending: true,
    );
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
      // Seule « Encaissé par » reste vide : ce paiement vient d'un autre poste.
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

  // Un reçu que l'établissement a retiré : le numéro barré ne dit pas
  // grand-chose seul, c'est la phrase qui explique. La rature la rend
  // seulement impossible à manquer.
  group('reçu annulé', () {
    EditiqueCacheEntry cancelled({String? reason = 'Erreur de montant'}) =>
        EditiqueCacheEntry(
          id: 'c-1',
          documentId: 'doc-1',
          documentNumber: 'ETL-RC-2526-000212',
          docType: 'RC',
          schoolId: 'school-1',
          sizeBytes: 1024,
          contentSha256: 'abc',
          cancelledAt: DateTime.utc(2026, 8, 6).millisecondsSinceEpoch,
          cancellationReason: reason,
          createdAt: 1000,
          lastAccessedAt: 1000,
        );

    testWidgets('barre le numéro et dit le motif', (tester) async {
      await _pump(
        tester,
        onDownload: () {},
        receiptNumber: 'ETL-RC-2526-000212',
        cancelledReceipt: cancelled(),
      );
      await tester.pumpAndSettle();

      final number = tester.widget<Text>(find.text('ETL-RC-2526-000212'));
      expect(number.style?.decoration, TextDecoration.lineThrough);
      expect(find.textContaining('Erreur de montant'), findsOneWidget);
      expect(find.textContaining('annulé'), findsOneWidget);
    });

    // Arbitrage du 2026-08-06 : la copie annulée se ressort quand même — la
    // rature et le motif sont à l'écran, la pièce ne trompe personne.
    testWidgets('laisse le téléchargement offert', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        onDownload: () => tapped++,
        receiptNumber: 'ETL-RC-2526-000212',
        cancelledReceipt: cancelled(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Télécharger le reçu'));
      expect(tapped, 1);
    });

    // Le motif vient du serveur : il peut manquer, et l'écran n'invente pas la
    // phrase absente.
    testWidgets('dit le retrait même sans motif', (tester) async {
      await _pump(
        tester,
        onDownload: () {},
        receiptNumber: 'ETL-RC-2526-000212',
        cancelledReceipt: cancelled(reason: null),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('annulé'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un reçu qui tient n est ni barré ni commenté', (tester) async {
      await _pump(
        tester,
        onDownload: () {},
        receiptNumber: 'ETL-RC-2526-000212',
      );
      await tester.pumpAndSettle();

      final number = tester.widget<Text>(find.text('ETL-RC-2526-000212'));
      expect(number.style?.decoration, isNot(TextDecoration.lineThrough));
      expect(find.textContaining('annulé'), findsNothing);
    });
  });

  // Le geste que porte « Télécharger le reçu ». Éprouvé ici parce qu'une revue
  // adversariale a montré ce que coûtait la mauvaise garde — et parce que la
  // décision vivait jusque-là dans l'arbre de widgets, hors de portée de tout
  // test.
  group('facturationReceiptGesture', () {
    EditiqueCacheEntry entry({
      String? documentId = 'doc-1',
      String? contentSha256 = 'abc',
      int? cancelledAt,
    }) => EditiqueCacheEntry(
      id: 'c-1',
      documentId: documentId,
      documentNumber: 'ETL-RC-2526-000212',
      docType: 'RC',
      schoolId: 'school-1',
      sizeBytes: 1024,
      contentSha256: contentSha256,
      cancelledAt: cancelledAt,
      createdAt: 1000,
      lastAccessedAt: 1000,
    );

    test('restitue une copie détenue', () {
      expect(
        facturationReceiptGesture(cached: entry(), isPendingSync: false),
        FacturationReceiptGesture.restitute,
      );
    });

    // LA régression trouvée par la revue adversariale. Garder sur les octets
    // faisait retomber ce cas sur l'ÉMISSION, qui rescelle l'instantané, brûle
    // un numéro d'une séquence auditée sans trou et repointe
    // `payment.receiptId` — alors que la route de téléchargement du serveur ne
    // filtre pas l'annulation et rendait la pièce gratuitement. Un reçu retiré
    // pour erreur de montant redevenait le reçu officiel du versement.
    test('restitue encore une pièce annulée dont les octets sont partis', () {
      expect(
        facturationReceiptGesture(
          cached: entry(contentSha256: null, cancelledAt: 1786013000000),
          isPendingSync: false,
        ),
        FacturationReceiptGesture.restitute,
      );
    });

    test('restitue une pièce en vigueur dont les octets sont partis', () {
      expect(
        facturationReceiptGesture(
          cached: entry(contentSha256: null),
          isPendingSync: false,
        ),
        FacturationReceiptGesture.restitute,
      );
    });

    // Le serveur n'expose aucune recherche par numéro : sans identifiant
    // d'archive, la restitution rendrait `NotFoundFailure`.
    test('émet quand aucun identifiant d archive ne désigne la pièce', () {
      expect(
        facturationReceiptGesture(
          cached: entry(documentId: null),
          isPendingSync: false,
        ),
        FacturationReceiptGesture.emit,
      );
      expect(
        facturationReceiptGesture(cached: null, isPendingSync: false),
        FacturationReceiptGesture.emit,
      );
    });

    test('n offre rien sur un encaissement pas encore remonté', () {
      expect(
        facturationReceiptGesture(cached: null, isPendingSync: true),
        FacturationReceiptGesture.none,
      );
    });

    // Une pièce adressable se restitue même hors synchro du versement : la
    // lecture n'a besoin que de l'identifiant de la PIÈCE.
    test('restitue malgré un versement non synchronisé', () {
      expect(
        facturationReceiptGesture(cached: entry(), isPendingSync: true),
        FacturationReceiptGesture.restitute,
      );
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

  // B-9 — aucune de ces modales n'a de champ, donc le clavier ne monte jamais
  // devant elles. Elles peuvent en revanche s'ouvrir alors qu'il est DÉJÀ levé
  // sur l'écran du dessous : `Dialog` ajoute les `viewInsets` à son
  // `insetPadding`, et il ne reste qu'une poignée de dp pour des zones figées
  // qui en réclament trois cents. C'est le seul scénario qui les faisait
  // déborder — mesuré à 106 px sur celle-ci avant la coquille.
  testWidgets('téléphone en PAYSAGE, clavier déjà levé : rien ne déborde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(731, 411);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await _pump(tester, onDownload: () {});
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloDialogBody), findsOneWidget);
  });
}
