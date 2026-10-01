import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_history_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_mapper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';

/// Lit un mois d'appel d'une classe : les jours appelés (sessions), les
/// retards et absences de la classe d'aujourd'hui, la clôture et l'état
/// d'envoi. Un élève parti de la classe n'y figure plus.
class ClassPresenceMonthReader {
  final ClassroomLocalDataSource roster;
  final AttendanceHistoryLocalDataSource history;
  final AttendanceClosureLocalDataSource closures;

  const ClassPresenceMonthReader({
    required this.roster,
    required this.history,
    required this.closures,
  });

  Future<ClassPresenceMonth> read(ClassMonthKey key) async {
    final students = ClassPresenceMapper.students(
      await roster.getRoster(key.classroomId),
    );
    final from = SchoolDayCalendar.firstOf(key.month);
    final to = SchoolDayCalendar.daysOf(key.month).last;
    final monthSessions = await history.sessionsBetween(
      classroomId: key.classroomId,
      academicYearId: key.academicYearId,
      from: from,
      to: to,
    );
    final syncOf = {
      for (final session in monthSessions)
        session.attendanceDate: session.isSynced
            ? RecordSyncState.synced
            : RecordSyncState.pending,
    };
    final byId = {for (final s in students) s.id: s};
    final incidents = <String, Map<String, ClassPresenceLine>>{};
    for (final row in await history.recordsBetween(
      classroomId: key.classroomId,
      academicYearId: key.academicYearId,
      from: from,
      to: to,
    )) {
      final student = byId[row.studentId];
      final sync = syncOf[row.attendanceDate];
      if (student == null || sync == null) continue;
      final line = ClassPresenceMapper.fromSession(student, row, sync);
      if (!line.status.isIncident) continue;
      (incidents[row.attendanceDate] ??= {})[student.id] = line;
    }
    return ClassPresenceMonth(
      classroomId: key.classroomId,
      academicYearId: key.academicYearId,
      month: key.month,
      students: students,
      calledDays: syncOf.keys.toSet(),
      incidents: incidents,
      closed: await closures.isClosed(
        classroomId: key.classroomId,
        academicYearId: key.academicYearId,
        month: key.month,
      ),
      sync: syncOf.values.contains(RecordSyncState.pending)
          ? RecordSyncState.pending
          : RecordSyncState.synced,
    );
  }
}
