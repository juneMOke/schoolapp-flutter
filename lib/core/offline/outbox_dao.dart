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
  ///
  /// [expectedCreatedAt] : garde anti-TOCTOU. Si fourni, on n'acquitte QUE si
  /// l'entrée porte toujours ce `created_at`. Une entrée **ré-enfilée** pendant
  /// le dispatch en vol (même id, `ConflictAlgorithm.replace`, nouveau
  /// `created_at`) ne doit PAS être acquittée : elle porte un nouvel état encore
  /// à pousser. Sans cette garde, `markAcked` puis `deleteAcked` purgeraient
  /// silencieusement une écriture non synchronisée (perte de données).
  Future<void> markAcked(String id, {int? expectedCreatedAt}) async {
    await _db.update(
      table,
      {'status': OutboxStatus.acked.dbValue, 'last_error': null},
      where: expectedCreatedAt == null ? 'id = ?' : 'id = ? AND created_at = ?',
      whereArgs: expectedCreatedAt == null ? [id] : [id, expectedCreatedAt],
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

  /// Entrées en erreur de synchro, plus récentes d'abord — alimente la feuille
  /// de reprise (diagnostic + requeue manuel). `SYNC_ERROR` étant terminal, ces
  /// entrées ne repartent JAMAIS d'elles-mêmes : sans cette lecture, elles sont
  /// invisibles et l'écriture est perdue sans que personne ne le sache.
  Future<List<OutboxEntry>> errors({int limit = 100}) async {
    final rows = await _db.query(
      table,
      where: 'status = ?',
      whereArgs: [OutboxStatus.syncError.dbValue],
      orderBy: 'created_at DESC, rowid DESC',
      limit: limit,
    );
    return rows.map(OutboxEntry.fromMap).toList();
  }

  /// Remet une entrée terminale (`SYNC_ERROR`) en file : `PENDING`, compteur de
  /// tentatives remis à zéro, barrière de backoff effacée, dernière erreur
  /// purgée. C'est le pendant explicite du re-enqueue implicite (réécriture du
  /// même id) — seule sortie de l'état terminal pour les agrégats-**événements**
  /// (`PAYMENT`, `CLASSROOM_TRANSFER`), dont l'id d'entrée est aléatoire et donc
  /// jamais réécrit par un nouveau geste utilisateur.
  ///
  /// Sûr par construction : le push est idempotent par clé métier (`aggregateId`)
  /// — un rejeu ne duplique pas, il ré-obtient l'agrégat existant.
  ///
  /// Ne touche QUE les entrées en `SYNC_ERROR` : requeue d'une entrée déjà
  /// `PENDING` (double tap, course avec un flush en vol) est un no-op, jamais une
  /// remise à zéro d'un backoff légitime.
  Future<int> requeue(String id) {
    return _db.update(
      table,
      {
        'status': OutboxStatus.pending.dbValue,
        'attempts': 0,
        'next_attempt_at': 0,
        'last_error': null,
      },
      where: 'id = ? AND status = ?',
      whereArgs: [id, OutboxStatus.syncError.dbValue],
    );
  }

  // PAS de `discard(id)` / `delete(id)` ici, et c'est délibéré.
  //
  // Supprimer une entrée d'outbox détruit son `aggregateId` — la SEULE clé
  // d'idempotence du contrat (`PaymentInput` : « sans identifiant stable, aucune
  // idempotence n'est possible » ; le back dédoublonne par id, jamais par clé
  // métier). Deux dégâts s'ensuivent, tous deux muets :
  //  - l'agrégat local reste dans son état non-acquitté et continue d'être
  //    composé comme abouti à l'écran (un paiement reste déduit du solde) ;
  //  - pire, `PENDING_SYNC` **immunise contre le pull** (les applicateurs sautent
  //    les lignes non acquittées pour ne pas écraser une écriture locale) : la
  //    divergence devient permanente et auto-scellée, plus rien ne peut la
  //    corriger, ni le push ni le serveur.
  //
  // Un abandon sûr doit donc, dans la MÊME transaction, sortir l'agrégat métier
  // de `PENDING_SYNC` vers un état « abandonné » visible — ce qui est un travail
  // par module, pas une méthode de socle. Tant qu'il n'existe pas, ne rien
  // supprimer : une entrée qui reste en erreur est réparable, une entrée
  // supprimée ne l'est plus.

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
