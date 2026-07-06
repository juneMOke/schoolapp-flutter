import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';

/// Accès sqflite à `disciplinary_cases` (DF-1). Écriture locale + enfilage
/// d'outbox dans une seule transaction (atomicité « fait / traitement enregistré »).
class DisciplinaryLocalDataSource {
  final Database _db;

  const DisciplinaryLocalDataSource(this._db);

  static const String table = 'disciplinary_cases';

  /// Cas d'un élève sur une année, du plus récent au plus ancien.
  Future<List<OfflineDisciplinaryCaseRow>> getCasesForStudent({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      table,
      where: 'student_id = ? AND academic_year_id = ?',
      whereArgs: [studentId, academicYearId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(OfflineDisciplinaryCaseRow.fromMap).toList(growable: false);
  }

  Future<OfflineDisciplinaryCaseRow?> getCase(String id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineDisciplinaryCaseRow.fromMap(rows.first);
  }

  /// Création du FAIT (régime A) : INSERT du cas + entrée d'outbox CREATE,
  /// atomiquement. `ConflictAlgorithm.replace` = idempotent sur l'uuid client.
  Future<void> createCaseWithOutbox({
    required OfflineDisciplinaryCaseRow row,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        table,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Traitement (régime C, LWW) : UPDATE status/sanction si `updatedAt` >= local,
  /// + entrée d'outbox UPDATE, atomiquement.
  Future<void> updateCaseWithOutbox({
    required String caseId,
    required String status,
    required String? sanction,
    required int updatedAt,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      final existing = await txn.query(
        table,
        columns: ['updated_at'],
        where: 'id = ?',
        whereArgs: [caseId],
        limit: 1,
      );
      final localUpdatedAt = existing.isEmpty
          ? null
          : (existing.first['updated_at'] as int?);
      if (localUpdatedAt == null || updatedAt >= localUpdatedAt) {
        await txn.update(
          table,
          {
            'status': status,
            'sanction': sanction,
            'updated_at': updatedAt,
            'sync_status': SyncState.pendingSync.dbValue,
            'synced_at': null,
          },
          where: 'id = ?',
          whereArgs: [caseId],
        );
      }
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Marque un cas comme synchronisé (après ACK serveur). Version optionnelle
  /// (si le back l'expose — DG-2).
  Future<void> markCaseSynced(
    String id, {
    int? version,
    required int syncedAt,
  }) async {
    await _db.update(
      table,
      {
        'sync_status': SyncState.synced.dbValue,
        'synced_at': syncedAt,
        'version': ?version,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
