import 'dart:convert';

import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/attendance_summary_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_json.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les résumés des mois clos du Pointage (`staff_attendance_summaries`) :
/// immuables, remplacés tels quels à chaque descente.
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

  /// Mois → résumé.
  Future<Map<String, AttendanceSummary>> forSchool(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
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
