import 'package:equatable/equatable.dart';

/// Où en est une correction de niveau, vue de ce poste.
enum LevelCorrectionStatus {
  /// Posée, pas encore accusée : l'inscription, ses créances et sa classe sont
  /// encore celles de l'ancien niveau.
  pending,

  /// Accusée par le serveur. Les nouvelles créances arrivent par la descente.
  applied,

  /// Refusée (422, terminal) : rien n'a changé au serveur.
  refused,
}

/// Une correction de niveau posée sur ce poste.
class LevelCorrection extends Equatable {
  final String id;
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String fromSchoolLevelId;
  final String toSchoolLevelId;
  final String toSchoolLevelGroupId;
  final String? toClassroomId;
  final String reason;
  final String correctedAt;
  final LevelCorrectionStatus status;

  /// Code stable du refus (`STALE_LEVEL`…), ou statut HTTP faute de code.
  final String? refusalCode;

  const LevelCorrection({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.fromSchoolLevelId,
    required this.toSchoolLevelId,
    required this.toSchoolLevelGroupId,
    required this.reason,
    required this.correctedAt,
    required this.status,
    this.toClassroomId,
    this.refusalCode,
  });

  @override
  List<Object?> get props => [
    id,
    enrollmentId,
    studentId,
    academicYearId,
    fromSchoolLevelId,
    toSchoolLevelId,
    toSchoolLevelGroupId,
    toClassroomId,
    reason,
    correctedAt,
    status,
    refusalCode,
  ];
}
