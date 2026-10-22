import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_dto.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/justification_decision_payload.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';

/// Type d'agrégat d'outbox d'une décision sur une justification.
const String kJustificationDecisionAggregateType =
    'ATTENDANCE_JUSTIFICATION_DECISION';

/// Les justifications d'absence des parents (`attendance_justifications`).
///
/// Deux écrivains, deux jeux de colonnes : le serveur (pull, accusé) écrit
/// la demande et son statut ; la tablette écrit sa décision en attente
/// (`local_*`). Aucun ne déborde sur l'autre.
class AttendanceJustificationLocalDataSource {
  final Database _db;

  const AttendanceJustificationLocalDataSource(this._db);

  static const String table = 'attendance_justifications';

  /// L'identité de l'élève vient du roster de l'année — sa classe d'alors
  /// d'abord, n'importe laquelle sinon (un élève transféré reste nommé).
  static const String _select =
      '''
    SELECT j.*,
      m.student_first_name, m.student_last_name, m.student_middle_name,
      c.name AS classroom_name
    FROM $table j
    LEFT JOIN ref_classroom_members m ON m.id = (
      SELECT id FROM ref_classroom_members
      WHERE student_id = j.student_id AND academic_year_id = j.academic_year_id
      ORDER BY (classroom_id = j.classroom_id) DESC
      LIMIT 1
    )
    LEFT JOIN ref_classrooms c ON c.id = j.classroom_id
  ''';

  /// Les justifications de l'année, l'absence la plus récente d'abord.
  Future<List<AttendanceJustification>> list(String academicYearId) async {
    final rows = await _db.rawQuery(
      '$_select WHERE j.academic_year_id = ? '
      'ORDER BY j.attendance_date DESC, j.submitted_at DESC',
      [academicYearId],
    );
    return rows.map(AttendanceJustificationRow.toEntity).toList();
  }

  /// Pose la décision de cette tablette et met son geste en file, en une
  /// transaction. `false` si la demande n'attend plus de décision (tranchée
  /// entre-temps, ou une décision déjà en route) : rien n'est écrit.
  Future<bool> recordDecision({
    required JustificationDecisionPayload payload,
    required String? schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final updated = await txn.update(
      table,
      {
        'local_gesture_id': payload.gestureId,
        'local_decision': payload.decision,
        'local_decision_note': payload.note,
        'local_decided_at': nowMs,
        'sync_status': SyncState.pendingSync.dbValue,
        'sync_error': null,
      },
      where: "id = ? AND status = 'PENDING' AND local_decision IS NULL",
      whereArgs: [payload.justificationId],
    );
    if (updated == 0) return false;
    await enqueueOutboxGesture(
      txn,
      entryId: payload.gestureId,
      type: kJustificationDecisionAggregateType,
      aggregateId: payload.justificationId,
      payload: payload.toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: payload.authorId,
    );
    return true;
  });

  /// L'accusé : la justification telle que le serveur la tient. Si une autre
  /// tablette a tranché autrement, c'est SA décision qui s'écrit, et la ligne
  /// le signale ([JustificationDecision] envoyée ≠ statut reçu).
  Future<void> applyAck(
    JustificationDecisionPayload payload,
    AttendanceJustificationDto justification,
  ) {
    final sent = JustificationDecision.fromApi(payload.decision)?.status;
    final received = JustificationStatus.fromApi(justification.status);
    return _db.update(
      table,
      {
        ...AttendanceJustificationRow.serverValues(justification),
        ...AttendanceJustificationRow.clearedDecision,
        'accept_blocked_code': null,
        'decided_elsewhere': sent != null && sent != received ? 1 : 0,
        'sync_status': SyncState.synced.dbValue,
        'sync_error': null,
      },
      where: 'id = ? AND local_gesture_id = ?',
      whereArgs: [payload.justificationId, payload.gestureId],
    );
  }

  /// Le geste n'est pas passé et la demande redevient « à traiter ».
  ///
  /// [acceptBlock] : l'acceptation est impossible, seul le refus reste.
  /// [refusal] : la raison d'un refus définitif à montrer ; `null` pour un
  /// échec qui ne regarde pas l'utilisateur.
  Future<void> revertDecision(
    JustificationDecisionPayload payload, {
    JustificationAcceptBlock? acceptBlock,
    String? refusal,
  }) => _db.update(
    table,
    {
      ...AttendanceJustificationRow.clearedDecision,
      'accept_blocked_code': ?acceptBlock?.code,
      'sync_status': refusal == null
          ? SyncState.synced.dbValue
          : SyncState.syncError.dbValue,
      'sync_error': refusal,
    },
    where: 'id = ? AND local_gesture_id = ?',
    whereArgs: [payload.justificationId, payload.gestureId],
  );

  /// L'avis « tranchée par un autre poste » a été montré.
  Future<void> acknowledgeDecidedElsewhere(String id) => _db.update(
    table,
    {'decided_elsewhere': 0},
    where: 'id = ?',
    whereArgs: [id],
  );

  /// Les justifications reçues du serveur. Une décision locale en route n'est
  /// pas touchée : c'est son accusé qui la réglera.
  Future<int> applyPulled(List<AttendanceJustificationDto> items) async {
    var applied = 0;
    await applyInBatches<AttendanceJustificationDto>(
      _db,
      items,
      apply: (txn, chunk) async {
        for (final item in chunk) {
          final values = AttendanceJustificationRow.serverValues(item);
          final decided = item.status != JustificationStatus.pending.apiValue;
          final updated = await txn.update(
            table,
            {
              ...values,
              // Une demande tranchée ne garde pas d'empêchement d'accepter.
              if (decided) 'accept_blocked_code': null,
            },
            where: 'id = ?',
            whereArgs: [item.id],
          );
          if (updated == 0) await txn.insert(table, values);
          applied++;
        }
      },
    );
    return applied;
  }
}
