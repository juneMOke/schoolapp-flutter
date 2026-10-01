import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_draft_mark_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_line.dart';

/// Les passages entre les lignes de la base (roster, appel, brouillon) et le
/// registre du domaine. Calcul pur.
abstract final class ClassPresenceMapper {
  /// La classe par ordre alphabétique (nom, post-nom, prénom), numérotée.
  static List<ClassPresenceStudent> students(List<ClassroomMemberDto> roster) {
    final unnumbered = [
      for (final member in roster)
        ClassPresenceStudent(
          id: member.studentId,
          firstName: member.studentFirstName,
          lastName: member.studentLastName,
          middleName: member.studentMiddleName,
          gender: StudentGenderX.fromApiValue(member.studentGender),
          number: 0,
        ),
    ]..sort(ClassPresenceStudent.compareNames);
    return [
      for (var i = 0; i < unnumbered.length; i++)
        ClassPresenceStudent(
          id: unnumbered[i].id,
          firstName: unnumbered[i].firstName,
          lastName: unnumbered[i].lastName,
          middleName: unnumbered[i].middleName,
          gender: unnumbered[i].gender,
          number: i + 1,
        ),
    ];
  }

  /// La ligne d'un élève dans un appel validé : son exception, ou présent.
  static ClassPresenceLine fromSession(
    ClassPresenceStudent student,
    AttendanceRecordRow? row,
    RecordSyncState sync,
  ) {
    if (row == null || !row.presenceStatus.isIncident) {
      return ClassPresenceLine(
        student: student,
        mark: const PresenceMark(status: PresenceStatus.present),
        sync: sync,
      );
    }
    final late = row.presenceStatus == PresenceStatus.late;
    return ClassPresenceLine.read(
      student: student,
      mark: PresenceMark(
        status: row.presenceStatus,
        arrival: late ? ClockTime.tryParse(row.arrivalTime) : null,
        lateMinutes: late ? row.lateMinutes ?? 0 : 0,
      ),
      reason: AbsenceReasonX.fromApiValue(row.absenceReason),
      note: row.absenceReasonNote,
      sync: sync,
    );
  }

  /// La ligne d'un élève dans le brouillon : sa marque, ou « à pointer ».
  static ClassPresenceLine fromDraft(
    ClassPresenceStudent student,
    AttendanceDraftMarkRow? row,
  ) {
    if (row == null || row.presenceStatus == PresenceStatus.none) {
      return ClassPresenceLine(
        student: student,
        mark: const PresenceMark.none(),
      );
    }
    final status = row.presenceStatus;
    return ClassPresenceLine.read(
      student: student,
      mark: PresenceMark(
        status: status,
        arrival: status.hasArrival ? ClockTime.tryParse(row.arrivalTime) : null,
        lateMinutes: status == PresenceStatus.late ? row.lateMinutes ?? 0 : 0,
      ),
      reason: AbsenceReasonX.fromApiValue(row.absenceReason),
      note: row.absenceReasonNote,
      sync: RecordSyncState.pending,
    );
  }

  /// La ligne de brouillon d'une marque ; `null` pour « à pointer », sauf
  /// sur un appel rouvert ([keepNone]) où « à pointer » doit masquer la
  /// ligne de l'appel en base.
  static AttendanceDraftMarkRow? draftRow(
    ClassPresenceLine line, {
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required int updatedAt,
    bool keepNone = false,
  }) {
    final mark = line.mark;
    if (mark.status == PresenceStatus.none && !keepNone) return null;
    final (reason, note) = line.wireReason;
    return AttendanceDraftMarkRow(
      classroomId: classroomId,
      attendanceDate: dateStr,
      academicYearId: academicYearId,
      studentId: line.student.id,
      status: AttendanceDraftMarkRow.statusWire(mark.status),
      arrivalTime: mark.arrival?.wire,
      lateMinutes: mark.status == PresenceStatus.late ? mark.lateMinutes : null,
      // Le motif d'origine d'un élève inconnu de cette tablette reste tel
      // quel : le brouillon n'est jamais sérialisé vers le serveur.
      absenceReason: reason == AbsenceReason.unsupported
          ? null
          : reason?.toApiValue(),
      absenceReasonNote: note,
      updatedAt: updatedAt,
    );
  }

  /// L'exception d'un retard ou d'une absence, à envoyer ; `null` pour un
  /// présent.
  static AttendanceDayLine? exception(ClassPresenceLine line) {
    final mark = line.mark;
    if (!mark.status.isIncident) return null;
    final (reason, note) = line.wireReason;
    final student = line.student;
    return AttendanceDayLine(
      studentId: student.id,
      studentFirstName: student.firstName,
      studentLastName: student.lastName,
      studentMiddleName: student.middleName,
      studentGender: student.gender.toApiValue(),
      status: mark.status,
      arrivalTime: mark.arrival?.wire,
      lateMinutes: mark.status == PresenceStatus.late ? mark.lateMinutes : null,
      absenceReason: reason?.toApiValue(),
      absenceReasonNote: note,
    );
  }
}
