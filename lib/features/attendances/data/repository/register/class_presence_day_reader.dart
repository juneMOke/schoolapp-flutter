import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_draft_mark_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_draft_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_mapper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';

/// Compose l'appel d'une classe pour un jour, à partir de trois sources :
///
/// - **pas d'appel** : la classe se lit dans le brouillon ;
/// - **appel validé** : la classe se lit dans l'appel en base ;
/// - **appel rouvert** : chaque élève **touché depuis la réouverture** se lit
///   dans le brouillon, les autres dans l'appel en base — tel qu'il est
///   *maintenant*, pas tel qu'il était à la réouverture. Une correction
///   reçue d'une autre tablette entre-temps reste donc visible, et la
///   revalidation la renvoie intacte au lieu de l'écraser.
///
/// Un mois clos ignore les brouillons : il n'y a plus rien à saisir.
class ClassPresenceDayReader {
  final AttendanceLocalDataSource sessions;
  final AttendanceDraftLocalDataSource drafts;
  final AttendanceClosureLocalDataSource closures;
  final ClassroomLocalDataSource roster;
  final PresenceScheduleReader scheduleReader;
  final OutboxDao outbox;
  final CurrentUserContext? currentUser;

  const ClassPresenceDayReader({
    required this.sessions,
    required this.drafts,
    required this.closures,
    required this.roster,
    required this.scheduleReader,
    required this.outbox,
    this.currentUser,
  });

  Future<ClassPresenceDay> read(ClassDayKey key) async {
    final students = ClassPresenceMapper.students(
      await roster.getRoster(key.classroomId),
    );
    final session = await sessions.getSession(
      classroomId: key.classroomId,
      dateStr: key.day,
      academicYearId: key.academicYearId,
    );
    final monthClosed = await closures.isClosed(
      classroomId: key.classroomId,
      academicYearId: key.academicYearId,
      month: key.day.substring(0, 7),
    );
    final reopened = session?.reopenedAt != null && !monthClosed;
    final (sync, refusal) = await _sendState(key, session);
    final marks = monthClosed || (session != null && !reopened)
        ? const <String, AttendanceDraftMarkRow>{}
        : await draftMarks(key);
    final records = session == null
        ? const <String, AttendanceRecordRow>{}
        : {
            for (final row in await sessions.getDayRecords(
              classroomId: key.classroomId,
              dateStr: key.day,
              academicYearId: key.academicYearId,
            ))
              row.studentId: row,
          };
    ClassPresenceLine lineOf(ClassPresenceStudent student) {
      final mark = marks[student.id];
      if (session == null || mark != null) {
        return ClassPresenceMapper.fromDraft(student, mark);
      }
      return ClassPresenceMapper.fromSession(
        student,
        records[student.id],
        sync,
      );
    }

    return ClassPresenceDay(
      classroomId: key.classroomId,
      academicYearId: key.academicYearId,
      day: key.day,
      lines: [for (final student in students) lineOf(student)],
      hasSession: session != null,
      reopened: reopened,
      takenBy: session?.takenBy,
      lastSentAt: session?.updatedAt,
      sync: sync,
      refusal: refusal,
      monthClosed: monthClosed,
      schedule: await scheduleReader.read(currentUser?.schoolId),
    );
  }

  /// Les marques du brouillon du jour, par élève.
  Future<Map<String, AttendanceDraftMarkRow>> draftMarks(
    ClassDayKey key,
  ) async => {
    for (final row in await drafts.marksOf(
      classroomId: key.classroomId,
      dateStr: key.day,
      academicYearId: key.academicYearId,
    ))
      row.studentId: row,
  };

  /// Où en est l'envoi de l'appel : au serveur, en file, ou refusé (avec la
  /// raison écrite par le serveur).
  Future<(RecordSyncState, String?)> _sendState(
    ClassDayKey key,
    AttendanceSessionRow? session,
  ) async {
    if (session == null || session.isSynced) {
      return (RecordSyncState.synced, null);
    }
    final entry = await outbox.byId(
      AttendanceDayWriter.outboxEntryId(
        key.classroomId,
        key.day,
        key.academicYearId,
      ),
    );
    if (entry != null && entry.status == OutboxStatus.syncError) {
      return (RecordSyncState.failed, entry.lastError);
    }
    return (RecordSyncState.pending, null);
  }
}
