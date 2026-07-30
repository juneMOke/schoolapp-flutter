import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';

/// Accès sqflite à l'agrégat d'appel (`attendance_sessions` + `attendance_records`).
///
/// Modèle SESSION du contrat 1.2.0 : la session est la **racine d'agrégat** dont
/// la seule existence lève l'ambiguïté des 3 états. Écriture par exception (seuls
/// les absents portent une ligne) + arbitrage LWW sur `updated_at`. La
/// matérialisation de la session, de ses exceptions et l'enfilage d'outbox se
/// font dans **une seule transaction** (atomicité « appel confirmé »).
class AttendanceLocalDataSource {
  final Database _db;

  const AttendanceLocalDataSource(this._db);

  static const String sessionsTable = 'attendance_sessions';
  static const String recordsTable = 'attendance_records';

  /// Session d'un `(classe, date, année)` ou `null` = **appel non fait**.
  Future<AttendanceSessionRow?> getSession({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final row = await _sessionByKey(
      _db,
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: academicYearId,
    );
    return row;
  }

  /// Exceptions matérialisées d'un jour (absents + retards). Un élève **sans
  /// ligne** sous une session = présent (dérivation côté repository).
  Future<List<AttendanceRecordRow>> getDayRecords({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      recordsTable,
      where:
          'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [classroomId, dateStr, academicYearId],
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }

  /// Confirme un appel (agrégat exhaustif). En une transaction :
  ///  1. **upsert de la session** sur la clé naturelle + LWW (`updated_at`
  ///     rebumpé même si seule une absence change) ;
  ///  2. **upsert des absences** (present=0), rattachées à la session ;
  ///  3. **réconciliation par différence** : toute exception de la session dont
  ///     l'élève n'est plus dans la liste d'absents est **supprimée** (retard
  ///     corrigé → l'élève sort simplement des exceptions) ;
  ///  4. enfilage de l'entrée d'outbox (id déterministe → coalescing du ré-appel).
  ///
  /// [session] porte l'`id` client (transport) ; s'il existe déjà une session
  /// pour la clé naturelle, son `id` local est **conservé** (id = transport,
  /// clé naturelle = vérité). [absentRows] ne contient QUE les absents.
  Future<void> confirmDailyAttendance({
    required AttendanceSessionRow session,
    required List<AttendanceRecordRow> absentRows,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      final existing = await _sessionByKey(
        txn,
        classroomId: session.classroomId,
        dateStr: session.attendanceDate,
        academicYearId: session.academicYearId,
      );

      // LWW à la granularité de l'agrégat : une session locale strictement plus
      // récente conserve la main (filet ; ne se produit pas en mono-tablette).
      if (existing != null && existing.updatedAt > session.updatedAt) {
        await OutboxDao(txn).enqueue(outboxEntry);
        return;
      }

      final sessionId = existing?.id ?? session.id;
      if (existing == null) {
        await txn.insert(sessionsTable, session.copyWithId(sessionId).toMap());
      } else {
        // Ne pas écraser les champs d'origine serveur (expected_count,
        // server_updated_at, version) avec les nuls d'une écriture locale.
        await txn.update(
          sessionsTable,
          {
            'taken_at': session.takenAt,
            'taken_by': session.takenBy,
            'updated_at': session.updatedAt,
            'sync_status': SyncState.pendingSync.dbValue,
            'synced_at': null,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }

      for (final row in absentRows) {
        await _upsertAbsence(txn, row.copyWithSessionId(sessionId));
      }
      await _reconcileByDifference(
        txn,
        sessionId: sessionId,
        keptStudentIds: absentRows.map((r) => r.studentId).toList(),
      );

      // Coalescing : l'id déterministe de l'entrée fait qu'un ré-appel du même
      // jour REMPLACE l'entrée en attente (ConflictAlgorithm.replace).
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Upsert d'une exception (present=0) sur sa clé naturelle, avec LWW.
  Future<void> _upsertAbsence(
    DatabaseExecutor txn,
    AttendanceRecordRow row,
  ) async {
    final existing = await _recordByKey(
      txn,
      studentId: row.studentId,
      dateStr: row.attendanceDate,
      academicYearId: row.academicYearId,
    );
    if (existing == null) {
      await txn.insert(recordsTable, row.toMap());
    } else if (row.updatedAt >= existing.updatedAt) {
      await txn.update(
        recordsTable,
        row.toMap()..['id'] = existing.id,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
    // sinon : ligne locale plus récente → LWW conserve l'existant.
  }

  /// Supprime les exceptions de [sessionId] dont l'élève n'est plus absent
  /// (réconciliation par différence, contrat §4 : DELETE, pas de soft-delete).
  Future<void> _reconcileByDifference(
    DatabaseExecutor txn, {
    required String sessionId,
    required List<String> keptStudentIds,
  }) async {
    if (keptStudentIds.isEmpty) {
      // Personne d'absent : toute exception de la session est caduque.
      await txn.delete(
        recordsTable,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      return;
    }
    final placeholders = List.filled(keptStudentIds.length, '?').join(',');
    await txn.delete(
      recordsTable,
      where: 'session_id = ? AND student_id NOT IN ($placeholders)',
      whereArgs: [sessionId, ...keptStudentIds],
    );
  }

  /// Marque l'appel d'un jour (session + exceptions) SYNCED après ACK serveur,
  /// et rapatrie les champs autoritaires de la réponse (AG-3) : `serverUpdatedAt`
  /// (visibilité) et `expectedCount` (snapshot roster serveur). Ceux-ci ne sont
  /// écrits que s'ils sont fournis (une écriture partielle ne les efface pas).
  Future<void> markDaySynced({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required int syncedAt,
    String? serverUpdatedAt,
    int? expectedCount,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        sessionsTable,
        {
          'sync_status': SyncState.synced.dbValue,
          'synced_at': syncedAt,
          'server_updated_at': ?serverUpdatedAt,
          'expected_count': ?expectedCount,
        },
        where:
            'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
        whereArgs: [classroomId, dateStr, academicYearId],
      );
      await txn.update(
        recordsTable,
        {'sync_status': SyncState.synced.dbValue, 'synced_at': syncedAt},
        where:
            'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
        whereArgs: [classroomId, dateStr, academicYearId],
      );
    });
  }

  /// Applique un lot de sessions pullées (upsert par clé naturelle + absences
  /// imbriquées réconciliées). Renvoie le nombre de sessions **effectivement**
  /// appliquées.
  ///
  /// Money-grade — le pull **ne clobbère jamais une écriture locale non
  /// synchronisée** : une session locale `PENDING_SYNC` (appel fait hors-ligne,
  /// pas encore poussé) est plus récente que tout ce que le serveur peut porter,
  /// on la **saute** (elle sera poussée puis réalignée par clé naturelle). Sinon
  /// on adopte l'état serveur (SYNCED) et on remplace ses exceptions (la liste
  /// pullée est exhaustive pour la session).
  Future<int> applyPulledSessions(
    List<PulledAttendanceSession> pulled,
    int syncedAt,
  ) async {
    var applied = 0;
    await applyInBatches<PulledAttendanceSession>(
      _db,
      pulled,
      apply: (txn, chunk) async {
        for (final item in chunk) {
          final existing = await _sessionByKey(
            txn,
            classroomId: item.session.classroomId,
            dateStr: item.session.attendanceDate,
            academicYearId: item.session.academicYearId,
          );
          // Écriture locale non synchronisée = gagnante : ne pas la remplacer.
          if (existing != null && !existing.isSynced) continue;

          final sessionId = existing?.id ?? item.session.id;
          final row = item.session.copyWithId(sessionId);
          if (existing == null) {
            await txn.insert(sessionsTable, row.toMap());
          } else {
            await txn.update(
              sessionsTable,
              row.toMap(),
              where: 'id = ?',
              whereArgs: [existing.id],
            );
          }

          // Réconciliation : les absences pullées sont exhaustives pour la session.
          await txn.delete(
            recordsTable,
            where: 'session_id = ?',
            whereArgs: [sessionId],
          );
          for (final absence in item.absences) {
            await txn.insert(
              recordsTable,
              absence.copyWithSessionId(sessionId).toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          applied++;
        }
      },
    );
    return applied;
  }

  /// Nombre d'absences locales d'un jour (present=0) — numérateur du taux AF-3.
  Future<int> countAbsences({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $recordsTable WHERE classroom_id = ? '
      'AND attendance_date = ? AND academic_year_id = ? AND present = 0',
      [classroomId, dateStr, academicYearId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Jours appelés** d'une classe sur une période (dénominateur des stats
  /// AF-3, §5) : nombre de sessions. [fromStr]/[toStr] nuls = année entière
  /// (les sessions sont déjà cadrées par `academic_year_id`).
  Future<int> countSessions({
    required String classroomId,
    required String academicYearId,
    String? fromStr,
    String? toStr,
  }) async {
    final where = StringBuffer('classroom_id = ? AND academic_year_id = ?');
    final args = <Object?>[classroomId, academicYearId];
    if (fromStr != null && toStr != null) {
      where.write(' AND attendance_date BETWEEN ? AND ?');
      args
        ..add(fromStr)
        ..add(toStr);
    }
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $sessionsTable WHERE $where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Jours appelés** d'une classe sur un intervalle à bornes **indépendantes**
  /// (F6, intervalles d'appartenance) : chaque borne inclusive s'applique seule
  /// (≠ [countSessions] qui exige les deux). `null` = borne ouverte de ce côté.
  Future<int> countSessionsBetween({
    required String classroomId,
    required String academicYearId,
    String? fromInclusive,
    String? toInclusive,
  }) async {
    final where = StringBuffer('classroom_id = ? AND academic_year_id = ?');
    final args = <Object?>[classroomId, academicYearId];
    if (fromInclusive != null) {
      where.write(' AND attendance_date >= ?');
      args.add(fromInclusive);
    }
    if (toInclusive != null) {
      where.write(' AND attendance_date <= ?');
      args.add(toInclusive);
    }
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $sessionsTable WHERE $where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Absences d'un élève** sur une période, détail complet (numérateur +
  /// motif/note des stats AF-3 §5), triées du plus récent au plus ancien.
  /// [fromStr]/[toStr] nuls = année entière.
  Future<List<AttendanceRecordRow>> getStudentAbsenceRecords({
    required String studentId,
    required String academicYearId,
    String? fromStr,
    String? toStr,
  }) async {
    final where = StringBuffer(
      'student_id = ? AND academic_year_id = ? AND present = 0',
    );
    final args = <Object?>[studentId, academicYearId];
    if (fromStr != null && toStr != null) {
      where.write(' AND attendance_date BETWEEN ? AND ?');
      args
        ..add(fromStr)
        ..add(toStr);
    }
    final rows = await _db.query(
      recordsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'attendance_date DESC',
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }

  Future<AttendanceSessionRow?> _sessionByKey(
    DatabaseExecutor db, {
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await db.query(
      sessionsTable,
      where:
          'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [classroomId, dateStr, academicYearId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceSessionRow.fromMap(rows.first);
  }

  Future<AttendanceRecordRow?> _recordByKey(
    DatabaseExecutor txn, {
    required String studentId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await txn.query(
      recordsTable,
      where: 'student_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [studentId, dateStr, academicYearId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceRecordRow.fromMap(rows.first);
  }
}
