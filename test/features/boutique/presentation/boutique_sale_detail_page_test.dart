import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_sale_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetDetail extends Mock implements GetBoutiqueSaleDetailUseCase {}

class _MockMarkPrinted extends Mock implements MarkSaleTicketPrintedUseCase {}

BoutiqueSaleLocalModel _sale({
  String? collectedByName = 'Mbala Céline',
  String? receiptNumber,
  String? receiptDocumentId,
  String syncStatus = 'SYNCED',
}) => BoutiqueSaleLocalModel(
  id: 'aaaabbbb-cccc-dddd',
  schoolId: 'E1',
  academicYearId: 'ay-1',
  payerLastName: 'Ndombo',
  payerMiddleName: 'Lelo',
  payerFirstName: 'Willy',
  payerPhoneNumber: '+243810220145',
  collectedByName: collectedByName,
  soldAt: '2026-08-30T09:42:00Z',
  receiptNumber: receiptNumber,
  receiptDocumentId: receiptDocumentId,
  syncStatus: syncStatus,
  updatedAt: 0,
);

const _line = BoutiqueSaleLineLocalModel(
  id: 'l-1',
  saleId: 'aaaabbbb-cccc-dddd',
  articleId: 'art-polo',
  articleLabel: 'Polo Lacoste',
  beneficiaryName: 'Kabeya Junior',
  size: 'M',
  quantity: 2,
  unitPriceInCents: 1750,
  lineTotalInCents: 3500,
  currency: 'USD',
);

SaleDetail _detail({
  BoutiqueSaleLocalModel? sale,
  DateTime? printedAt,
  List<BoutiqueSaleLineLocalModel> lines = const [_line],
}) => SaleDetail(
  sale: RecordedSale(sale: sale ?? _sale(), lines: lines),
  ticketPrintedAt: printedAt,
);

void main() {
  late _MockGetDetail getDetail;
  late _MockMarkPrinted markPrinted;

  setUp(() {
    getDetail = _MockGetDetail();
    markPrinted = _MockMarkPrinted();
    GetIt.I.registerFactory<GetBoutiqueSaleDetailUseCase>(() => getDetail);
    GetIt.I.registerFactory<MarkSaleTicketPrintedUseCase>(() => markPrinted);
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpDetail(WidgetTester tester, {SaleDetail? detail}) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => getDetail(any())).thenAnswer(
      (_) async =>
          detail == null ? const Left(NotFoundFailure()) : Right(detail),
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: BoutiqueSaleDetailPage(
          saleId: 'aaaabbbb-cccc-dddd',
          levelLabels: {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la fiche montre le contenu FIGÉ de la vente', (tester) async {
    // Les libellés et les prix viennent de la vente, jamais du catalogue : une
    // vente d'hier doit rester lisible après le retrait de son article (I-6).
    await pumpDetail(tester, detail: _detail());

    expect(find.text('Polo Lacoste'), findsOneWidget);
    expect(find.textContaining('Kabeya Junior'), findsOneWidget);
    expect(find.textContaining('Taille M'), findsOneWidget);
    expect(find.text('Ndombo Lelo Willy'), findsOneWidget);
  });

  testWidgets('« encaissé par » est NOMMÉ', (tester) async {
    // Sur une caisse tenue à plusieurs, c'est la seule ligne qui dit qui a pris
    // l'argent.
    await pumpDetail(tester, detail: _detail());

    expect(find.text('Encaissé par'), findsOneWidget);
    expect(find.text('Mbala Céline'), findsOneWidget);
  });

  testWidgets('sans caissier, le manque se DIT', (tester) async {
    // Un blanc ferait chercher ce qu'on a oublié de remplir ; la mention dit
    // que le renseignement n'existe pas.
    await pumpDetail(
      tester,
      detail: _detail(sale: _sale(collectedByName: null)),
    );

    expect(find.text('Caissier non renseigné'), findsOneWidget);
  });

  testWidgets('ticket jamais imprimé : le libellé dit IMPRIMER', (
    tester,
  ) async {
    await pumpDetail(tester, detail: _detail());

    expect(find.text('Imprimer le ticket'), findsOneWidget);
    expect(find.textContaining('jamais imprimé'), findsOneWidget);
  });

  testWidgets('ticket déjà sorti : le libellé dit RÉIMPRIMER, et la date', (
    tester,
  ) async {
    // La mention informe, elle ne garde pas la porte : un papier se déchire, et
    // refuser la seconde sortie laisserait le guichet sans recours.
    await pumpDetail(
      tester,
      detail: _detail(printedAt: DateTime(2026, 8, 30, 10, 15)),
    );

    expect(find.text('Réimprimer le ticket'), findsOneWidget);
    expect(find.textContaining('30/08/2026 10:15'), findsOneWidget);
    // Toujours actif.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Réimprimer le ticket'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('sans reçu scellé, on ANNONCE l\'attente au lieu du bouton', (
    tester,
  ) async {
    // Offrir le bouton avant ferait ouvrir une pièce introuvable.
    await pumpDetail(tester, detail: _detail());

    expect(find.text('Ouvrir le reçu scellé'), findsNothing);
    expect(find.textContaining('scellé à la synchronisation'), findsOneWidget);
  });

  testWidgets('avec son identifiant d\'archive, le reçu s\'ouvre', (
    tester,
  ) async {
    // C'est l'IDENTIFIANT qui décide, pas le numéro : le numéro s'imprime,
    // l'identifiant seul permet de re-télécharger la pièce.
    await pumpDetail(
      tester,
      detail: _detail(
        sale: _sale(receiptNumber: 'RV-2026-0007', receiptDocumentId: 'doc-7'),
      ),
    );

    expect(find.text('Ouvrir le reçu scellé'), findsOneWidget);
    expect(find.text('RV-2026-0007'), findsWidgets);
  });

  testWidgets('une vente en attente le DIT sur sa fiche', (tester) async {
    await pumpDetail(
      tester,
      detail: _detail(sale: _sale(syncStatus: 'PENDING_SYNC')),
    );

    expect(find.textContaining('pas encore partie au serveur'), findsOneWidget);
  });

  testWidgets('vente disparue : ce n\'est PAS une panne de lecture', (
    tester,
  ) async {
    // « Historique illisible » ferait réessayer indéfiniment une lecture qui
    // répond correctement qu'il n'y a rien.
    await pumpDetail(tester);

    expect(find.text('Vente introuvable'), findsOneWidget);
    expect(find.text('Historique illisible'), findsNothing);
  });
}
