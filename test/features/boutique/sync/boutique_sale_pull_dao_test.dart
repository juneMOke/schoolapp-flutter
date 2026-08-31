import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_pull_dao.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

BoutiqueSaleDeltaDto _delta({
  String id = 'vente-1',
  String? receiptDocumentId,
  String? payerName = 'NDOMBO Lelo Willy',
  String? payerLastName = 'Ndombo',
  String? collectedByName = 'Moke Junior',
  List<BoutiqueSaleLineDeltaDto>? lines,
}) => BoutiqueSaleDeltaDto(
  id: id,
  academicYearId: 'ay-1',
  payerName: payerName,
  payerLastName: payerLastName,
  payerMiddleName: payerLastName == null ? null : 'Lelo',
  payerFirstName: payerLastName == null ? null : 'Willy',
  payerPhoneNumber: '+243810220145',
  collectedById: 'u2',
  collectedByName: collectedByName,
  amounts: MoneyBag.of(const [Money(3500, 'USD')]),
  soldAt: '2026-08-29T11:42:00Z',
  receiptDocumentId: receiptDocumentId,
  lines:
      lines ??
      const [
        BoutiqueSaleLineDeltaDto(
          id: 'l1',
          articleId: 'art-polo',
          articleLabel: 'Polo Lacoste',
          quantity: 1,
          unitPriceInCents: 1500,
          lineTotalInCents: 1500,
          currency: 'USD',
        ),
      ],
  serverUpdatedAt: '2026-08-29T11:45:00Z',
);

void main() {
  late Database db;
  late BoutiqueSalePullDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSalePullDao(db);
  });
  tearDown(() async => db.close());

  Future<int> apply(List<BoutiqueSaleDeltaDto> sales) =>
      dao.applySales(sales, schoolId: 'E1', nowMs: 1000);

  test('une vente de l\'autre guichet descend, lignes comprises', () async {
    // Sans ce flux, le total de caisse d'un poste ne compterait que ce que ce
    // poste a lui-même vendu : deux caissiers verraient deux caisses
    // différentes le même jour.
    expect(await apply([_delta()]), 1);

    final sale = (await db.query('boutique_sales')).single;
    // Le montant vit sur les lignes : la vente n'en porte plus. La fixture
    // déclarait 3 500 pour une ligne à 1 500 — un écart que rien ne pouvait
    // relever tant que la vente portait son propre total.
    final lines = await db.query('boutique_sale_lines');
    expect(
      lines.fold<int>(0, (t, l) => t + (l['line_total_in_cents'] as int)),
      1500,
    );
    expect(sale['collected_by_name'], 'Moke Junior');
    expect(await db.query('boutique_sale_lines'), hasLength(1));
  });

  test('une vente descendue est SYNCED', () async {
    await apply([_delta()]);

    expect((await db.query('boutique_sales')).single['sync_status'], 'SYNCED');
  });

  group('💀 réconciliation du reçu', () {
    test('un scellement TARDIF redescend et remplace le provisoire', () async {
      // La seule voie différée par laquelle un reçu scellé après coup revient.
      // Sans elle, le poste garderait un ticket provisoire pour une pièce qui
      // existe.
      await apply([_delta()]);
      expect(
        (await db.query('boutique_sales')).single['receipt_document_id'],
        isNull,
      );

      await apply([_delta(receiptDocumentId: 'doc-1')]);

      expect(
        (await db.query('boutique_sales')).single['receipt_document_id'],
        'doc-1',
      );
    });

    test('le NUMÉRO n\'est jamais inventé depuis le delta', () async {
      // Le delta ne porte que l'identifiant d'archive. Un ticket réimprimé avec
      // un faux numéro serait pire qu'un ticket provisoire honnête.
      await apply([_delta(receiptDocumentId: 'doc-1')]);

      expect(
        (await db.query('boutique_sales')).single['receipt_number'],
        isNull,
      );
    });
  });

  group('identité du payeur', () {
    test('le triplet descendu alimente le répertoire', () async {
      await apply([_delta()]);

      final sale = (await db.query('boutique_sales')).single;
      expect(sale['payer_last_name'], 'Ndombo');
      expect(sale['payer_first_name'], 'Willy');
    });

    test('sans triplet, le nom composé remplit le champ Nom', () async {
      // Vente d'avant l'alignement du contrat : le redécouper serait une
      // invention — « Ndombo Lelo Willy » ne se redécoupe pas sans se tromper.
      await apply([_delta(payerLastName: null)]);

      final sale = (await db.query('boutique_sales')).single;
      expect(sale['payer_last_name'], 'NDOMBO Lelo Willy');
      expect(sale['payer_first_name'], isNull);
    });
  });

  test('les lignes sont REMPLACÉES, jamais fusionnées', () async {
    // Le serveur fait autorité sur le panier d'une vente qu'il a enregistrée :
    // une fusion laisserait vivre une ligne que l'ingestion a écartée, et le
    // ticket ne se recompterait plus.
    await apply([
      _delta(
        lines: const [
          BoutiqueSaleLineDeltaDto(
            id: 'l1',
            articleId: 'a1',
            quantity: 1,
            unitPriceInCents: 100,
            lineTotalInCents: 100,
            currency: 'USD',
          ),
          BoutiqueSaleLineDeltaDto(
            id: 'l2',
            articleId: 'a2',
            quantity: 1,
            unitPriceInCents: 200,
            lineTotalInCents: 200,
            currency: 'USD',
          ),
        ],
      ),
    ]);

    await apply([
      _delta(
        lines: const [
          BoutiqueSaleLineDeltaDto(
            id: 'l1',
            articleId: 'a1',
            quantity: 1,
            unitPriceInCents: 100,
            lineTotalInCents: 100,
            currency: 'USD',
          ),
        ],
      ),
    ]);

    expect(await db.query('boutique_sale_lines'), hasLength(1));
  });

  test(
    'un libellé absent retombe sur l\'identifiant, jamais sur du vide',
    () async {
      // Une ligne muette sur un ticket est pire qu'une ligne technique.
      await apply([
        _delta(
          lines: const [
            BoutiqueSaleLineDeltaDto(
              id: 'l1',
              articleId: 'art-inconnu',
              quantity: 1,
              unitPriceInCents: 100,
              lineTotalInCents: 100,
              currency: 'USD',
            ),
          ],
        ),
      ]);

      expect(
        (await db.query('boutique_sale_lines')).single['article_label'],
        'art-inconnu',
      );
    },
  );

  test('une page vide n\'écrit rien', () async {
    expect(await apply([]), 0);
    expect(await db.query('boutique_sales'), isEmpty);
  });
}
