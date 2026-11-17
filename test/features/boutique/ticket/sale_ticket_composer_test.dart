import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_lines.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

const _labels = SaleTicketLabels(
  documentTitle: 'Reçu de vente',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  referenceLabel: 'Réf.',
  dateLabel: 'Date :',
  enteredAtLabel: 'Saisi le',
  cashierLabel: 'Caissier :',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  articlesLabel: 'Articles',
  beneficiaryPrefix: 'pour',
  sizePrefix: 'T.',
  unitSuffix: '/u',
  totalLabel: 'Total',
  amountReceivedLabel: 'Montant reçu',
  rateLabel: 'Taux',
  remainingLabel: 'Reste à payer',
  noRefundNotice: 'Aucun remboursement.',
  signatureLabel: 'Signature du caissier',
  verificationNotice: 'Scannez pour vérifier ce reçu',
  thanksNotice: 'Merci.',
  editorNotice: 'Reçu édité par ETEELO CONNECT',
  editorSite: 'eteeloconnect.com',
);

const _saleId = 'aaaabbbb-cccc-dddd-eeee-ffff00001111';

RecordedSale _recorded({
  String soldAt = '2026-08-29T11:42:00Z',
  String? receiptNumber = 'ETL-RV-2526-000413',
  String? emittedOn,
  String? verificationUrl,
  String? collectedByName = 'Moke Junior',
  String? levelId,
}) => RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: _saleId,
    schoolId: 'E1',
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    payerName: 'NDOMBO Lelo Willy',
    payerPhoneNumber: '+243810220145',
    collectedByName: collectedByName,
    soldAt: soldAt,
    receiptNumber: receiptNumber,
    receiptEmittedOn: emittedOn,
    receiptVerificationUrl: verificationUrl,
    updatedAt: 0,
  ),
  lines: [
    BoutiqueSaleLineLocalModel(
      id: 'l1',
      saleId: _saleId,
      articleId: 'art-polo',
      articleLabel: 'Polo Lacoste',
      schoolLevelId: levelId,
      quantity: 1,
      unitPriceInCents: 1500,
      lineTotalInCents: 1500,
      currency: 'USD',
    ),
  ],
);

void main() {
  late Database db;
  late SaleTicketComposer composer;

  setUp(() async {
    db = await openFullOfflineDb();
    composer = SaleTicketComposer(db);
  });
  tearDown(() async => db.close());

  Future<SaleTicketModel> compose(
    RecordedSale sale, {
    Map<String, String> levels = const {},
  }) async => (await composer.compose(
    sale,
    labels: _labels,
    levelLabels: levels,
  )).getOrElse(() => throw StateError('attendu un ticket'));

  group('💀 pas de numéro définitif, pas de ticket', () {
    test('sans numéro : ReceiptAwaitingNumberFailure', () async {
      final result = await composer.compose(
        _recorded(receiptNumber: null),
        labels: _labels,
        levelLabels: const {},
      );

      expect(
        result.fold((f) => f, (_) => null),
        isA<ReceiptAwaitingNumberFailure>(),
      );
    });

    test('un numéro blanc vaut une absence', () async {
      final result = await composer.compose(
        _recorded(receiptNumber: '   '),
        labels: _labels,
        levelLabels: const {},
      );

      expect(result.isLeft(), isTrue);
    });

    test('avec un numéro, le ticket porte CE numéro', () async {
      final model = await compose(_recorded());

      expect(model.receiptNumber, 'ETL-RV-2526-000413');
    });
  });

  test(
    'le ticket date la vente à l\'heure de l\'école, pas du poste',
    () async {
      // 23 h 30 UTC le 29 = 0 h 30 le 30 à Kinshasa, quel que soit le fuseau
      // de la tablette.
      final model = await compose(_recorded(soldAt: '2026-08-29T23:30:00Z'));

      expect(
        (model.soldAt.day, model.soldAt.hour, model.soldAt.minute),
        (30, 0, 30),
      );
    },
  );

  test('le jour d\'émission et le QR viennent de la vente', () async {
    final model = await compose(
      _recorded(
        emittedOn: '2026-08-30',
        verificationUrl: 'https://verify.eteeloconnect.com/d/abc',
      ),
    );

    expect(model.receiptIssuedOn, DateTime(2026, 8, 30));
    expect(model.verificationUrl, 'https://verify.eteeloconnect.com/d/abc');
  });

  test('sans eux, ni date d\'émission ni QR', () async {
    final model = await compose(_recorded());

    expect(model.receiptIssuedOn, isNull);
    expect(model.verificationUrl, isNull);
  });

  test('une école inconnue N\'EMPÊCHE PAS le ticket', () async {
    final model = await compose(_recorded());

    expect(model.school.name, isEmpty);
    expect(model.totals, MoneyBag.of(const [Money(1500, 'USD')]));
  });

  test('l\'école de la vente donne l\'en-tête COMPLET', () async {
    await db.insert('ref_school', {
      'id': 'E1',
      'name': 'Complexe Scolaire La Colombe',
      'address': '14, av. de la Justice',
      'municipality': 'Gombe',
      'city': 'Kinshasa',
      'email': 'contact@colombe.cd',
      'phone': '+243810000000',
      'till_phone': '+243811111111',
    });

    final school = (await compose(_recorded())).school;

    expect(school.name, 'Complexe Scolaire La Colombe');
    expect(school.address, '14, av. de la Justice');
    expect(school.locality, 'Kinshasa');
    expect(school.email, 'contact@colombe.cd');
    expect(school.phone, '+243810000000');
    expect(school.tillPhone, '+243811111111');
  });

  test('seule l\'école de la vente nomme le ticket', () async {
    await db.insert('ref_school', {
      'id': 'E2',
      'name': 'Une autre école',
      'municipality': 'Limete',
      'city': 'Kinshasa',
    });

    final model = await compose(_recorded());

    expect(model.school.name, isEmpty);
  });

  test('le nom composé du payeur est celui qui a été figé', () async {
    final model = await compose(_recorded());

    expect(model.payerFullName, 'NDOMBO Lelo Willy');
  });

  test('le libellé du niveau est résolu par l\'appelant', () async {
    final model = await compose(
      _recorded(levelId: 'lvl-1'),
      levels: const {'lvl-1': '1ère humanités'},
    );

    expect(model.lines.single.levelLabel, '1ère humanités');
  });

  test('un niveau absent du référentiel ne casse rien', () async {
    final model = await compose(_recorded(levelId: 'lvl-inconnu'));

    expect(model.lines.single.levelLabel, isNull);
  });

  group('le montant reçu', () {
    test('lu sur les lignes d\'encaissement de la vente', () async {
      await db.insert(
        'boutique_sale_tenders',
        const BoutiqueSaleTenderLocalModel(
          id: 't1',
          saleId: _saleId,
          amountInCents: 4200000,
          currency: 'CDF',
          rateMicros: 2800 * ExchangeRate.scale,
          pivotCurrency: 'USD',
        ).toMap(),
      );

      final model = await compose(_recorded());

      expect(model.tenders, const [
        TicketTenderLine(
          amountInCents: 4200000,
          currency: 'CDF',
          rateMicros: 2800 * ExchangeRate.scale,
          pivotCurrency: 'USD',
        ),
      ]);
    });

    test('sans ligne d\'encaissement, le panier lui-même', () async {
      final model = await compose(_recorded());

      expect(model.tenders, const [
        TicketTenderLine(
          amountInCents: 1500,
          currency: 'USD',
          pivotCurrency: 'USD',
        ),
      ]);
    });
  });

  test('💀 le reste est TOUJOURS zéro, dans chaque devise', () async {
    final model = await compose(_recorded());

    expect(model.remaining.isAllZero, isTrue);
    expect(model.remaining.currencies, model.totals.currencies);
  });
}
