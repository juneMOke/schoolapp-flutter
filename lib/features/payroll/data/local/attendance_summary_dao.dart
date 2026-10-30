import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_gesture_dao.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/payroll/data/sync/attendance_summary_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les résumés des mois clos du Pointage (`staff_attendance_summaries`),
/// remplacés tels quels à chaque descente.
///
/// Un mois rouvert par la direction redescend sans clôture (`closedAt: null`,
/// `agents: []`) : son résumé est **effacé**, pas remplacé — la Paie juge un
/// mois clos dès que son résumé existe. À la nouvelle clôture, il revient
/// avec ses nouveaux chiffres.
class AttendanceSummaryDao {
  final PayrollStore _store;

  AttendanceSummaryDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'staff_attendance_summaries';

  Future<int> applyPulled(
    List<AttendanceSummaryDto> items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items.isEmpty || schoolId.isEmpty) return 0;
    await _store.transaction((txn) async {
      for (final item in items) {
        if (item.closedAt == null) {
          await txn.delete(
            table,
            where: 'school_id = ? AND month = ?',
            whereArgs: [schoolId, item.month],
          );
          continue;
        }
        await txn.insert(table, {
          'school_id': schoolId,
          'month': item.month,
          'closed_at': item.closedAt,
          'agents': jsonEncode(item.agents),
          'server_updated_at': item.serverUpdatedAt,
          'updated_at': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return items.length;
  }

  /// Mois → résumé. Un mois dont la réouverture attend encore son envoi
  /// n'est plus clos pour la Paie : sinon on validerait une paie que la
  /// réouverture, partie après, ferait refuser (ou l'inverse).
  Future<Map<String, AttendanceSummary>> forSchool(String schoolId) async {
    final rows = await _store.db.rawQuery(
      'SELECT s.* FROM $table s WHERE s.school_id = ? AND NOT EXISTS ('
      'SELECT 1 FROM ${StaffAttendanceGestureDao.table} g '
      'JOIN ${OutboxDao.table} o '
      "ON o.id = '${StaffAttendanceGestureDao.aggregateType}:' || g.id "
      "WHERE g.school_id = s.school_id AND g.period_start = s.month || '-01' "
      'AND g.gesture = ? AND g.sync_status = ? AND o.status = ?)',
      [
        schoolId,
        StaffAttendanceGesture.reopenMonth.wire,
        RecordSyncState.pending.dbValue,
        OutboxStatus.pending.dbValue,
      ],
    );
    return {
      for (final row in rows)
        row['month']! as String: AttendanceSummary(
          month: row['month']! as String,
          closedAt: row['closed_at'] as String?,
          agents: _agents(row['agents']),
        ),
    };
  }

  static Map<String, AttendanceAgentSummary> _agents(Object? raw) {
    Object? decoded;
    try {
      decoded = raw is String ? jsonDecode(raw) : null;
    } catch (_) {
      decoded = null;
    }
    if (decoded is! List) return const {};
    return {
      for (final agent in decoded)
        if (agent is Map && agent.text('staffMemberId') != null)
          agent.text('staffMemberId')!: AttendanceAgentSummary(
            workedMinutes: agent.integer('workedMinutes') ?? 0,
            unjustifiedAbsences: agent.integer('unjustifiedAbsences') ?? 0,
            justifiedAbsences: agent.integer('justifiedAbsences') ?? 0,
            lates: agent.integer('lates') ?? 0,
            lateMinutes: agent.integer('lateMinutes') ?? 0,
          ),
    };
  }
}
