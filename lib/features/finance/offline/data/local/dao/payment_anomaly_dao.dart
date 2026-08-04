import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';

/// Anomalies de synchro d'un encaissement (ADR-012 D-5, amendé).
///
/// Volontairement hors de l'outbox : une entrée acquittée y est **supprimée**
/// à la fin du flush, et son motif effacé par un clic sur « Réessayer ». Une
/// anomalie doit survivre aux deux et ne s'éteindre que sur accusé explicite.
class PaymentAnomalyDao {
  static const String _table = 'payment_anomalies';

  final DatabaseExecutor _db;

  const PaymentAnomalyDao(this._db);

  /// Enregistre une anomalie. Idempotent sur `(payment_id, kind)` : un rejeu de
  /// l'ACK ne doit pas empiler des doublons, et surtout ne doit pas **rouvrir**
  /// une anomalie déjà traitée par un opérateur — d'où `ignore` plutôt que
  /// `replace`.
  Future<void> record(PaymentAnomaly anomaly) async {
    await _db.insert(
      _table,
      anomaly.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Anomalies non encore traitées, la plus récente en tête.
  Future<List<PaymentAnomaly>> openAnomalies() async {
    final rows = await _db.query(
      _table,
      where: 'acknowledged_at IS NULL',
      orderBy: 'detected_at DESC',
    );
    return rows.map(PaymentAnomaly.fromMap).toList(growable: false);
  }

  Future<int> openCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE acknowledged_at IS NULL',
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Accuse réception. C'est le SEUL chemin qui éteint une anomalie : elle ne
  /// disparaît ni par rejeu, ni par purge, ni par une action de synchro.
  Future<void> acknowledge({
    required String id,
    required String acknowledgedBy,
    required int nowMs,
  }) async {
    await _db.update(
      _table,
      {'acknowledged_at': nowMs, 'acknowledged_by': acknowledgedBy},
      where: 'id = ? AND acknowledged_at IS NULL',
      whereArgs: [id],
    );
  }
}
