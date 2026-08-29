import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

const _labels = SaleTicketLabels(
  documentTitle: 'Reçu de vente',
  provisionalBanner: 'Document provisoire',
  provisionalNotice: 'Scellé à la synchro.',
  sealedNotice: 'Vaut quittance',
  payerLabel: 'PAYEUR :',
  phoneLabel: 'Tél.',
  cashierLabel: 'Caissier :',
  totalLabel: 'TOTAL',
  cashReceivedLabel: 'Espèces reçues',
  remainingLabel: 'Reste à payer',
  beneficiaryPrefix: 'pour',
  sizePrefix: 'T.',
  unitSuffix: '/u',
  noRefundNotice: 'Aucun remboursement.',
);

RecordedSale _recorded({
  String? receiptNumber,
  String? collectedByName = 'Moke Junior',
  String? levelId,
}) => RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: 'aaaabbbb-cccc-dddd-eeee-ffff00001111',
    schoolId: 'E1',
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    payerName: 'NDOMBO Lelo Willy',
    payerPhoneNumber: '+243810220145',
    collectedByName: collectedByName,
    totalInCents: 1500,
    currency: 'USD',
    soldAt: '2026-08-29T11:42:00Z',
    receiptNumber: receiptNumber,
    updatedAt: 0,
  ),
  lines: [
    BoutiqueSaleLineLocalModel(
      id: 'l1',
      saleId: 'aaaabbbb-cccc-dddd-eeee-ffff00001111',
      articleId: 'art-polo',
      articleLabel: 'Polo Lacoste',
      schoolLevelId: levelId,
      quantity: 1,
      unitPriceInCents: 1500,
      lineTotalInCents: 1500,
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
  }) => composer.compose(sale, labels: _labels, levelLabels: levels);

  test('sans numéro de reçu, le ticket est PROVISOIRE', () async {
    final model = await compose(_recorded());

    expect(model.isProvisional, isTrue);
    expect(model.reference, startsWith('PROV-'));
  });

  test('avec un numéro, il est SCELLÉ — même hors ligne', () async {
    // `isProvisional` se lit sur l'absence de NUMÉRO, pas sur l'état réseau :
    // une vente dont l'ACK n'a rendu aucun document reste provisoire même en
    // ligne, et c'est exactement ce que le porteur doit savoir.
    final model = await compose(_recorded(receiptNumber: 'ETL-RV-2526-000413'));

    expect(model.isProvisional, isFalse);
    expect(model.reference, 'ETL-RV-2526-000413');
  });

  test('la référence provisoire tient sur un rouleau', () async {
    final model = await compose(_recorded());

    // 48 colonnes : une référence trop longue s'enroulerait et casserait
    // l'alignement de tout le gabarit.
    expect(model.reference.length, lessThanOrEqualTo(20));
  });

  test('une école inconnue N\'EMPÊCHE PAS le ticket', () async {
    // Il vaut par son montant, son payeur et son caissier — pas par son
    // en-tête. Refuser d'imprimer laisserait le client repartir sans preuve.
    final model = await compose(_recorded());

    expect(model.schoolName, isEmpty);
    expect(model.totalInCents, 1500);
  });

  test('l\'école connue nomme le ticket', () async {
    await db.insert('ref_school', {
      'id': 'E1',
      'name': 'Complexe Scolaire La Colombe',
      'address': '14, av. de la Justice',
      'municipality': 'Gombe',
      'city': 'Kinshasa',
    });

    final model = await compose(_recorded());

    expect(model.schoolName, 'Complexe Scolaire La Colombe');
    expect(model.schoolAddress, contains('Gombe'));
  });

  test('le nom composé du payeur est celui qui a été figé', () async {
    // Le même que le serveur dérivera : le ticket du guichet et le reçu scellé
    // doivent dire la même chose.
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
    // Le ticket sort sans la mention plutôt qu'avec un identifiant brut, que
    // personne au guichet ne sait lire.
    final model = await compose(_recorded(levelId: 'lvl-inconnu'));

    expect(model.lines.single.levelLabel, isNull);
  });

  test('💀 le reste est TOUJOURS zéro, et le reçu égale le total', () async {
    final model = await compose(_recorded());

    expect(model.remainingInCents, 0);
    expect(model.cashReceivedInCents, model.totalInCents);
  });
}
