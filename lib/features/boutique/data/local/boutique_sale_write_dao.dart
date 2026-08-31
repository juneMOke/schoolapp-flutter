import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_sync_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture d'une vente encaissée.
///
/// **Une seule transaction pour la vente, ses lignes et son entrée d'outbox.**
/// Si l'une des trois manquait, l'argent serait dans un état que rien ne
/// rattrape : une vente sans outbox ne partirait jamais, une entrée sans vente
/// pousserait un panier introuvable.
class BoutiqueSaleWriteDao {
  final Database _db;

  const BoutiqueSaleWriteDao(this._db);

  /// Type d'agrégat de l'outbox. Le handler s'y abonne.
  static const String aggregateType = 'BOUTIQUE_SALE';

  Future<void> recordSale({
    required BoutiqueSaleLocalModel sale,
    required List<BoutiqueSaleLineLocalModel> lines,
    required BoutiqueSaleRequest request,
    required String outboxEntryId,
    required String schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'boutique_sales',
        sale.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final line in lines) {
        await txn.insert(
          'boutique_sale_lines',
          line.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await OutboxDao(txn).enqueue(
        OutboxEntry(
          id: outboxEntryId,
          aggregateType: aggregateType,
          aggregateId: sale.id,
          operation: OutboxOperation.create,
          payload: jsonEncode(request.toJson()),
          // ⚠️ Sans `schoolId`, l'entrée devient inéligible au flush scopé
          // école — seul rempart contre un rejeu inter-établissement après
          // reconnexion sur une tablette réaffectée.
          schoolId: schoolId,
          createdAt: nowMs,
        ),
      );
    });
  }

  /// Applique l'ACK du serveur : la vente passe `SYNCED` et reçoit son reçu.
  ///
  /// **Le numéro et l'identifiant d'archive viennent de `documents[]`**, pas du
  /// seul `sale.receiptDocumentId` : le contrat autorise l'un sans l'autre, et
  /// s'en remettre au second a déjà valu un ACK qui annonçait un reçu sans
  /// moyen de le retrouver.
  ///
  /// Un ACK **sans document** n'est pas un échec : la vente est enregistrée
  /// côté serveur, la caisse garde son ticket provisoire et réclamera le scellé
  /// plus tard.
  Future<void> applySaleAck(
    String saleId,
    BoutiqueSaleResponse ack, {
    required int nowMs,
  }) async {
    await _db.update(
      'boutique_sales',
      {
        'sync_status': 'SYNCED',
        'sync_error': null,
        'synced_at': nowMs,
        'receipt_document_id': ack.receiptDocumentId,
        'receipt_number': ack.receiptNumber,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );

    // Le prix que le catalogue serveur disait, ligne par ligne. Conservé même
    // quand il coïncide : il permet de relire une vente sans rejouer un
    // catalogue qui a pu bouger depuis.
    for (final divergence in ack.divergences) {
      final lineId = divergence.lineId;
      final catalogPrice = divergence.catalogPriceInCents;
      if (lineId == null || catalogPrice == null) continue;
      await _db.update(
        'boutique_sale_lines',
        {'catalog_price_in_cents': catalogPrice},
        where: 'id = ?',
        whereArgs: [lineId],
      );
    }
  }

  /// Bascule une vente en échec **terminal**, avec la raison.
  ///
  /// Le montant reste lisible en local : l'argent reçu n'est jamais « reperdu »
  /// parce que le serveur l'a refusé.
  Future<void> markSaleFailed(String saleId, String reason) => _db.update(
    'boutique_sales',
    {'sync_status': 'SYNC_ERROR', 'sync_error': reason},
    where: 'id = ?',
    whereArgs: [saleId],
  );
}
