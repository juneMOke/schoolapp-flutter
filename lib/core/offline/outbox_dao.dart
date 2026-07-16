import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Accès à la table `outbox`. Écrit/relit les entrées de la file de push.
/// Typé sur [DatabaseExecutor] pour fonctionner aussi bien avec la base
/// (production, SQLCipher) qu'à l'intérieur d'une transaction ou en test (ffi).
class OutboxDao {
  final DatabaseExecutor _db;

  const OutboxDao(this._db);

  static const String table = 'outbox';

  /// Enfile un agrégat. Remplace une éventuelle entrée de même id (re-enqueue).
  Future<void> enqueue(OutboxEntry entry) async {
    await _db.insert(
      table,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Entrées prêtes à pousser (PENDING dont la barrière de backoff est passée),
  /// en ordre FIFO strict (created_at puis rowid). C'est cet ordre qui garantit
  /// qu'un agrégat créé avant (ex. ENROLLMENT) part avant un agrégat dépendant
  /// (ex. PAYMENT du même élève).
  Future<List<OutboxEntry>> pendingReady(int nowMs, {int limit = 50}) async {
    final rows = await _db.query(
      table,
      where: 'status = ? AND next_attempt_at <= ?',
      whereArgs: [OutboxStatus.pending.dbValue, nowMs],
      orderBy: 'created_at ASC, rowid ASC',
      limit: limit,
    );
    return rows.map(OutboxEntry.fromMap).toList();
  }

  /// Entrées PENDING d'une école donnée (garde-fou tenant au flush).
  Future<List<OutboxEntry>> pendingReadyForSchool(
    String schoolId,
    int nowMs, {
    int limit = 50,
  }) async {
    final rows = await _db.query(
      table,
      where: 'status = ? AND next_attempt_at <= ? AND school_id = ?',
      whereArgs: [OutboxStatus.pending.dbValue, nowMs, schoolId],
      orderBy: 'created_at ASC, rowid ASC',
      limit: limit,
    );
    return rows.map(OutboxEntry.fromMap).toList();
  }

  /// Marque une entrée comme acquittée (ACK serveur reçu).
  Future<void> markAcked(String id) async {
    await _db.update(
      table,
      {'status': OutboxStatus.acked.dbValue, 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marque une entrée en erreur métier (rejet validation) — non rejouable
  /// automatiquement, à corriger côté présentation.
  Future<void> markSyncError(String id, String? error) async {
    await _db.update(
      table,
      {'status': OutboxStatus.syncError.dbValue, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reprogramme une entrée après une erreur transitoire (réseau) : reste
  /// PENDING, incrémente les tentatives, repousse la barrière de backoff.
  Future<void> reschedule(
    String id, {
    required int attempts,
    required int nextAttemptAt,
    String? lastError,
  }) async {
    await _db.update(
      table,
      {
        'status': OutboxStatus.pending.dbValue,
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt,
        'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Repousse une entrée **en attente d'une dépendance** (pas un échec) : reste
  /// PENDING, `next_attempt_at` avancé d'un délai fixe court, **sans** toucher
  /// `attempts` (donc jamais de poison ni de backoff). Cf.
  /// `OutboxDispatchOutcome.blocked`.
  Future<void> defer(
    String id, {
    required int nextAttemptAt,
    String? reason,
  }) async {
    await _db.update(
      table,
      {
        'status': OutboxStatus.pending.dbValue,
        'next_attempt_at': nextAttemptAt,
        'last_error': reason,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Nombre d'entrées encore en attente (badge « en attente de synchro »).
  Future<int> pendingCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table WHERE status = ?',
      [OutboxStatus.pending.dbValue],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Nombre d'entrées en erreur de synchro (rejet métier non rejouable
  /// automatiquement) — alimente l'état « conflit » de la pastille globale.
  Future<int> errorCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table WHERE status = ?',
      [OutboxStatus.syncError.dbValue],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Purge les entrées acquittées (housekeeping optionnel).
  Future<int> deleteAcked() {
    return _db.delete(
      table,
      where: 'status = ?',
      whereArgs: [OutboxStatus.acked.dbValue],
    );
  }
}
