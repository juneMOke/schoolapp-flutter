import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

/// Ligne d'appel poussée au serveur (AF-2). Snapshot élève obligatoire (colonnes
/// NOT NULL back). `updatedAt` (ISO) = arbitre last-write-wins côté serveur.
/// Parsing manuel (payload d'outbox) — pas de build_runner.
class OfflineAttendanceUpdateModel extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final bool present;
  final String? absenceReason;
  final String? absenceReasonNote;

  /// ISO-8601 — horloge client (LWW). Dépend de back AG-2.
  final String updatedAt;

  const OfflineAttendanceUpdateModel({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.present,
    this.absenceReason,
    this.absenceReasonNote,
    required this.updatedAt,
  });

  /// Depuis une mise à jour de domaine + l'horodatage LWW (epoch ms → ISO).
  factory OfflineAttendanceUpdateModel.fromEntity(
    AttendanceUpdate update, {
    required int updatedAtMs,
  }) => OfflineAttendanceUpdateModel(
    studentId: update.studentId,
    studentFirstName: update.studentFirstName,
    studentLastName: update.studentLastName,
    studentMiddleName: update.studentMiddleName,
    studentGender: update.studentGender.toApiValue(),
    present: update.present,
    absenceReason: update.present ? null : update.absenceReason?.toApiValue(),
    absenceReasonNote: update.present ? null : update.absenceReasonNote,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      updatedAtMs,
      isUtc: true,
    ).toIso8601String(),
  );

  factory OfflineAttendanceUpdateModel.fromJson(Map<String, dynamic> json) =>
      OfflineAttendanceUpdateModel(
        studentId: json['studentId'] as String,
        studentFirstName: json['studentFirstName'] as String,
        studentLastName: json['studentLastName'] as String,
        studentMiddleName: json['studentMiddleName'] as String?,
        studentGender: (json['studentGender'] as String?) ?? 'OTHER',
        present: json['present'] as bool? ?? true,
        absenceReason: json['absenceReason'] as String?,
        absenceReasonNote: json['absenceReasonNote'] as String?,
        updatedAt: json['updatedAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': studentId,
    'studentFirstName': studentFirstName,
    'studentLastName': studentLastName,
    'studentMiddleName': studentMiddleName,
    'studentGender': studentGender,
    'present': present,
    'absenceReason': absenceReason,
    'absenceReasonNote': absenceReasonNote,
    'updatedAt': updatedAt,
  };

  bool get isAbsent => !present;

  AbsenceReason? get absenceReasonEnum =>
      AbsenceReasonX.fromApiValue(absenceReason);

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    present,
    absenceReason,
    absenceReasonNote,
    updatedAt,
  ];
}
