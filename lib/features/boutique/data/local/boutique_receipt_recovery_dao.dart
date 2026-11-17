import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La marque « reçu de vente manquant » : une entrée d'outbox qui réclame le
/// reçu scellé qu'un accusé n'a pas rapporté.
///
/// Pendant de `ReceiptRecoveryDao` (le versement). Le scellement d'une vente
/// est *best-effort* côté serveur : un ACK peut revenir sans `documents`, et
/// le ticket — qui n'imprime qu'avec le numéro définitif — attendrait alors
/// pour toujours. La marque passe par l'outbox, et pas par un second appel
/// dans le handler de la vente : un défaut de PAPIER ne doit jamais se mettre
/// sur le chemin de l'ARGENT.
///
/// ⚠️ Un autre type d'agrégat que la vente, délibérément : la sonde de clôture
/// de caisse ne compte que `BOUTIQUE_SALE`, et un reçu en retard n'est pas de
/// l'argent en suspens.
class BoutiqueReceiptRecoveryDao {
  final DatabaseExecutor _db;

  const BoutiqueReceiptRecoveryDao(this._db);

  static const String aggregateType = 'BOUTIQUE_SALE_RECEIPT';
  static const String saleIdKey = 'saleId';

  /// Une seule marque par vente : l'identifiant est dérivé, et l'insertion
  /// ignore le doublon. Un ACK rejoué ne pose pas une seconde réclamation.
  static String entryIdOf(String saleId) => 'sale-receipt-$saleId';

  /// Pose la marque, dans la transaction de l'appelant.
  static Future<void> markMissingIn(
    DatabaseExecutor txn, {
    required String saleId,
    required int nowMs,
  }) async {
    final rows = await txn.query(
      'boutique_sales',
      columns: const ['school_id'],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    final entry = OutboxEntry(
      id: entryIdOf(saleId),
      aggregateType: aggregateType,
      aggregateId: saleId,
      operation: OutboxOperation.create,
      payload: jsonEncode({saleIdKey: saleId}),
      // Garde-fou tenant : sans école, l'entrée serait inéligible au flush
      // scopé, seul rempart contre un rejeu inter-établissement.
      schoolId: rows.isEmpty ? null : rows.first['school_id'] as String?,
      createdAt: nowMs,
    );
    await txn.insert(
      OutboxDao.table,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Le numéro du reçu de la vente — `''` s'il manque encore, `null` si la
  /// vente a quitté ce poste.
  Future<String?> receiptNumberOf(String saleId) async {
    final rows = await _db.query(
      'boutique_sales',
      columns: const ['receipt_number'],
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (rows.first['receipt_number'] as String?)?.trim() ?? '';
  }
}
