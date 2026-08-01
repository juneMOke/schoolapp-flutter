import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_time_slot_row.dart';

/// Accès sqflite aux tables de **référence** de l'emploi du temps
/// (`ref_time_slots`, `ref_recurring_sessions`). Read-only côté métier : ces
/// tables ne sont jamais écrites par une action utilisateur, uniquement peuplées
/// par le pull → l'application d'un delta est un simple upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC` (aucune écriture
/// locale à protéger).
///
/// **Partition par compte** : les séances sont cadrées enseignant côté serveur,
/// mais la base est partagée par tous les comptes de la tablette. Toute
/// écriture est donc estampillée `owner_uid` et toute lecture filtrée dessus
/// (cf. `core/offline/owner_scope.dart`). L'estampille est posée ICI, à partir
/// du propriétaire fourni par l'appelant : elle ne dépend d'aucun champ du
/// payload serveur, et le modèle de ligne ne peut pas la contredire.
///
/// `ref_time_slots` n'est PAS partitionnée : c'est un référentiel d'école, pas
/// d'enseignant — deux profs du même établissement partagent la même trame.
class ScheduleRefLocalDataSource {
  final Database _db;

  const ScheduleRefLocalDataSource(this._db);

  static const String timeSlotsTable = 'ref_time_slots';
  static const String sessionsTable = 'ref_recurring_sessions';

  // ── Application du pull ─────────────────────────────────────────────────────

  Future<int> applyPulledTimeSlots(List<RefTimeSlotRow> rows) async {
    var applied = 0;
    await applyInBatches<RefTimeSlotRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(
            timeSlotsTable,
            row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          applied++;
        }
      },
    );
    return applied;
  }

  /// Applique un delta de séances au nom de [ownerUid] (compte connecté au
  /// moment du pull — l'endpoint étant cadré enseignant, tout ce qui arrive lui
  /// appartient par construction).
  Future<int> applyPulledSessions(
    List<RefRecurringSessionRow> rows, {
    required String? ownerUid,
  }) async {
    final owner = ownerKey(ownerUid);
    var applied = 0;
    await applyInBatches<RefRecurringSessionRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(sessionsTable, {
            ...row.toMap(),
            'owner_uid': owner,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        }
      },
    );
    return applied;
  }

  // ── Lectures (emploi du temps local) ────────────────────────────────────────

  /// Trame horaire de l'école, dans l'ordre métier d'affichage.
  Future<List<RefTimeSlotRow>> getTimeSlots() async {
    final rows = await _db.query(timeSlotsTable, orderBy: 'slot_order ASC');
    return rows.map(RefTimeSlotRow.fromMap).toList(growable: false);
  }

  /// Séances récurrentes d'une année pour [ownerUid] (emploi du temps type).
  Future<List<RefRecurringSessionRow>> getSessionsForYear(
    String academicYearId, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      sessionsTable,
      where: 'academic_year_id = ? AND owner_uid = ?',
      whereArgs: [academicYearId, ownerKey(ownerUid)],
      orderBy:
          'id ASC', // ordre déterministe (résolution de collision de cellule)
    );
    return rows.map(RefRecurringSessionRow.fromMap).toList(growable: false);
  }

  /// Toutes les séances récurrentes de [ownerUid], toutes années confondues.
  Future<List<RefRecurringSessionRow>> getAllSessions({
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      sessionsTable,
      where: 'owner_uid = ?',
      whereArgs: [ownerKey(ownerUid)],
      orderBy: 'id ASC',
    );
    return rows.map(RefRecurringSessionRow.fromMap).toList(growable: false);
  }
}
