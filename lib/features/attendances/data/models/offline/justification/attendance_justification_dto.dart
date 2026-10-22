import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';

/// Une justification telle que le serveur la tient : ligne du pull
/// `attendance.justifications` et réponse de la décision.
class AttendanceJustificationDto extends Equatable {
  final String id;
  final String studentId;
  final String classroomId;
  final String academicYearId;

  /// `YYYY-MM-DD`.
  final String attendanceDate;
  final String? parentId;

  /// Valeur du contrat (`SICKNESS`, `FAMILY_EMERGENCY`, `TRANSPORT`, `OTHER`).
  final String reason;
  final String? note;
  final String? submittedAt;
  final AttachmentRef? file;

  /// `PENDING`, `ACCEPTED` ou `REJECTED`.
  final String status;
  final String? decidedAt;
  final String? decidedBy;
  final String? decisionNote;
  final String? decisionGestureId;
  final String? serverUpdatedAt;

  const AttendanceJustificationDto({
    required this.id,
    required this.studentId,
    required this.classroomId,
    required this.academicYearId,
    required this.attendanceDate,
    required this.reason,
    required this.status,
    this.parentId,
    this.note,
    this.submittedAt,
    this.file,
    this.decidedAt,
    this.decidedBy,
    this.decisionNote,
    this.decisionGestureId,
    this.serverUpdatedAt,
  });

  /// Lève sur une ligne sans identité : la page l'écarte et avance.
  factory AttendanceJustificationDto.fromJson(Map<String, dynamic> json) =>
      AttendanceJustificationDto(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        classroomId: json['classroomId'] as String,
        academicYearId: json['academicYearId'] as String,
        // Le serveur peut renvoyer un instant : on n'en garde que le jour.
        attendanceDate: (json['attendanceDate'] as String).substring(0, 10),
        parentId: json['parentId'] as String?,
        reason: json['reason'] as String? ?? 'OTHER',
        note: json['note'] as String?,
        submittedAt: json['submittedAt'] as String?,
        file: AttachmentRef.tryParse(json['file']),
        status: json['status'] as String? ?? 'PENDING',
        decidedAt: json['decidedAt'] as String?,
        decidedBy: json['decidedBy'] as String?,
        decisionNote: json['decisionNote'] as String?,
        decisionGestureId: json['decisionGestureId'] as String?,
        serverUpdatedAt: json['serverUpdatedAt'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    studentId,
    classroomId,
    academicYearId,
    attendanceDate,
    parentId,
    reason,
    note,
    submittedAt,
    file,
    status,
    decidedAt,
    decidedBy,
    decisionNote,
    decisionGestureId,
    serverUpdatedAt,
  ];
}
