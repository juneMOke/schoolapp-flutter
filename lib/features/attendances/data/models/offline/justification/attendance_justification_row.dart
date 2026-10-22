import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/justification/attendance_justification_dto.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/attendance_justification.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/justification/justification_enums.dart';

/// La correspondance entre une ligne `attendance_justifications` et le reste :
/// ce que le serveur y écrit, et ce que l'écran en lit.
abstract final class AttendanceJustificationRow {
  /// Les colonnes que le serveur tient — et elles seules : un pull ne touche
  /// jamais la décision locale (`local_*`) ni l'état d'envoi.
  static Map<String, Object?> serverValues(AttendanceJustificationDto dto) => {
    'id': dto.id,
    'student_id': dto.studentId,
    'classroom_id': dto.classroomId,
    'academic_year_id': dto.academicYearId,
    'attendance_date': dto.attendanceDate,
    'parent_id': dto.parentId,
    'reason': dto.reason,
    'note': dto.note,
    'submitted_at': dto.submittedAt,
    'file_name': dto.file?.name,
    'file_mime_type': dto.file?.mimeType,
    'file_size_bytes': dto.file?.sizeBytes,
    'file_sha256': dto.file?.sha256,
    'status': dto.status,
    'decided_at': dto.decidedAt,
    'decided_by': dto.decidedBy,
    'decision_note': dto.decisionNote,
    'server_updated_at': dto.serverUpdatedAt,
  };

  /// Les colonnes d'une décision locale, vidées.
  static const Map<String, Object?> clearedDecision = {
    'local_gesture_id': null,
    'local_decision': null,
    'local_decision_note': null,
    'local_decided_at': null,
  };

  /// La ligne lue avec l'identité de l'élève et le nom de la classe (colonnes
  /// `student_*` et `classroom_name` de la requête de lecture).
  static AttendanceJustification toEntity(Map<String, Object?> row) {
    final sha = row['file_sha256'] as String?;
    return AttendanceJustification(
      id: row['id']! as String,
      studentId: row['student_id']! as String,
      classroomId: row['classroom_id']! as String,
      academicYearId: row['academic_year_id']! as String,
      attendanceDate: row['attendance_date']! as String,
      reason:
          AbsenceReasonX.fromApiValue(row['reason'] as String?) ??
          AbsenceReason.other,
      note: row['note'] as String?,
      submittedAt: DateTime.tryParse(row['submitted_at'] as String? ?? ''),
      attachment: sha == null
          ? null
          : AttachmentRef(
              name: row['file_name'] as String? ?? '',
              mimeType: row['file_mime_type'] as String? ?? '',
              sizeBytes: row['file_size_bytes'] as int? ?? 0,
              sha256: sha,
            ),
      status: JustificationStatus.fromApi(row['status'] as String?),
      decidedAt: DateTime.tryParse(row['decided_at'] as String? ?? ''),
      decisionNote: row['decision_note'] as String?,
      localDecision: JustificationDecision.fromApi(
        row['local_decision'] as String?,
      ),
      sync: SyncState.fromDbValue(row['sync_status'] as String?),
      refusal: row['sync_error'] as String?,
      acceptBlock: JustificationAcceptBlock.fromCode(
        row['accept_blocked_code'] as String?,
      ),
      decidedElsewhere: (row['decided_elsewhere'] as int? ?? 0) == 1,
      studentFirstName: row['student_first_name'] as String? ?? '',
      studentLastName: row['student_last_name'] as String? ?? '',
      studentMiddleName: row['student_middle_name'] as String?,
      classroomName: row['classroom_name'] as String?,
    );
  }
}
