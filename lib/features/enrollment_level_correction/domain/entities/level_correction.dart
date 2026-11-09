import 'package:equatable/equatable.dart';

/// Où en est une correction de niveau, vue de ce poste.
enum LevelCorrectionStatus {
  /// Posée, pas encore accusée : l'inscription, ses créances et sa classe sont
  /// encore celles de l'ancien niveau.
  pending,

  /// Posée, mais son envoi est abandonné : la file l'a écartée après trop
  /// d'échecs (réseau, serveur), sans que le serveur ait jugé le geste. Rien
  /// n'a changé, l'encaissement n'est plus retenu ; le geste peut être relancé
  /// depuis la file, ou remplacé par une nouvelle correction.
  stalled,

  /// Accusée par le serveur, pas encore descendue : le dossier montre encore
  /// l'ancien niveau, et ses créances peuvent être celles de l'ancienne grille.
  /// L'encaissement reste retenu, aucune nouvelle correction ne part.
  applied,

  /// Accusée **et** descendue : l'inscription et ses créances sont celles du
  /// nouveau niveau. Plus rien n'est retenu.
  settled,

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
