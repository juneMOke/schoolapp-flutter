import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// L'écriture d'un reçu **réclamé** : ce qu'elle pose, et surtout ce qu'elle
/// refuse de toucher.
///
/// La vente est déjà partie et déjà acquittée quand ce code s'exécute. Seule sa
/// pièce arrive en retard — donc rien de l'état de synchro n'a à bouger, et un
/// champ que le serveur n'a pas communiqué ne doit pas effacer celui qu'un ACK
/// antérieur avait posé.
void main() {
  late Database db;
  late BoutiqueSaleWriteDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueSaleWriteDao(db);
  });

  tearDown(() async => db.close());

  /// La vente est semée par `toMap()`, le chemin de la production : une carte
  /// écrite à la main finirait par oublier une colonne que le schéma exige.
  Future<void> seedSyncedSale({
    String? receiptNumber,
    String? receiptDocumentId,
  }) async {
    await db.insert(
      'boutique_sales',
      BoutiqueSaleLocalModel(
        id: 's-1',
        schoolId: 'E1',
        academicYearId: 'ay-1',
        soldAt: '2026-09-19T08:00:00Z',
        receiptNumber: receiptNumber,
        receiptDocumentId: receiptDocumentId,
        syncStatus: 'SYNCED',
        updatedAt: 500,
      ).toMap(),
    );
  }

  Future<Map<String, Object?>> saleRow() async => (await db.query(
    'boutique_sales',
    where: 'id = ?',
    whereArgs: ['s-1'],
  )).single;

  test('la reclamation pose l identifiant ET le numero', () async {
    await seedSyncedSale();

    await dao.applyClaimedReceipt(
      's-1',
      nowMs: 900,
      documentId: 'doc-7',
      documentNumber: 'ETL-RV-2526-000413',
    );

    final row = await saleRow();
    expect(row['receipt_document_id'], 'doc-7');
    expect(row['receipt_number'], 'ETL-RV-2526-000413');
    expect(row['updated_at'], 900);
  });

  test('elle ne touche PAS l etat de synchro', () async {
    // C'est ce qui la distingue d'`applySaleAck` : la synchro de cette vente
    // n'est pas en cause, et la réécrire ferait passer pour neuf un
    // acquittement vieux de trois jours.
    await seedSyncedSale();
    final before = await saleRow();

    await dao.applyClaimedReceipt('s-1', nowMs: 900, documentId: 'doc-7');

    final after = await saleRow();
    expect(after['sync_status'], before['sync_status']);
    expect(after['synced_at'], before['synced_at']);
    expect(after['sync_error'], before['sync_error']);
  });

  test('un numero absent n ECRASE pas celui deja connu', () async {
    // Le numéro ne voyage que dans un `Content-Disposition` que le contrat ne
    // documente sur aucune route : le serveur peut très bien rendre la pièce
    // sans lui. Écrire ce `null` effacerait le numéro posé par l'ACK.
    await seedSyncedSale(receiptNumber: 'ETL-RV-2526-000413');

    await dao.applyClaimedReceipt(
      's-1',
      nowMs: 900,
      documentId: 'doc-7',
      documentNumber: null,
    );

    final row = await saleRow();
    expect(row['receipt_number'], 'ETL-RV-2526-000413');
    expect(row['receipt_document_id'], 'doc-7');
  });

  test('un identifiant absent n ECRASE pas celui deja connu', () async {
    await seedSyncedSale(receiptDocumentId: 'doc-1');

    await dao.applyClaimedReceipt(
      's-1',
      nowMs: 900,
      documentNumber: 'ETL-RV-2526-000413',
    );

    final row = await saleRow();
    expect(row['receipt_document_id'], 'doc-1');
    expect(row['receipt_number'], 'ETL-RV-2526-000413');
  });

  test('rien d exploitable : AUCUNE ecriture, pas meme updated_at', () async {
    // Bouger `updated_at` ferait paraître changée une vente dont rien n'a
    // changé.
    await seedSyncedSale();

    await dao.applyClaimedReceipt('s-1', nowMs: 900);

    final row = await saleRow();
    expect(row['updated_at'], 500);
    expect(row['receipt_document_id'], isNull);
    expect(row['receipt_number'], isNull);
  });

  test('une valeur reduite a des espaces vaut absente', () async {
    await seedSyncedSale(receiptNumber: 'ETL-RV-2526-000413');

    await dao.applyClaimedReceipt(
      's-1',
      nowMs: 900,
      documentId: '   ',
      documentNumber: '  ',
    );

    final row = await saleRow();
    expect(row['updated_at'], 500);
    expect(row['receipt_number'], 'ETL-RV-2526-000413');
    expect(row['receipt_document_id'], isNull);
  });

  test('les espaces autour d une valeur utile sont retires', () async {
    await seedSyncedSale();

    await dao.applyClaimedReceipt(
      's-1',
      nowMs: 900,
      documentId: ' doc-7 ',
      documentNumber: ' ETL-RV-2526-000413 ',
    );

    final row = await saleRow();
    expect(row['receipt_document_id'], 'doc-7');
    expect(row['receipt_number'], 'ETL-RV-2526-000413');
  });

  test('elle ne touche qu une seule vente', () async {
    await seedSyncedSale();
    await db.insert(
      'boutique_sales',
      const BoutiqueSaleLocalModel(
        id: 's-2',
        schoolId: 'E1',
        academicYearId: 'ay-1',
        soldAt: '2026-09-19T09:00:00Z',
        syncStatus: 'SYNCED',
        updatedAt: 500,
      ).toMap(),
    );

    await dao.applyClaimedReceipt('s-1', nowMs: 900, documentId: 'doc-7');

    final other = (await db.query(
      'boutique_sales',
      where: 'id = ?',
      whereArgs: ['s-2'],
    )).single;
    expect(other['receipt_document_id'], isNull);
    expect(other['updated_at'], 500);
  });
}
