import 'package:equatable/equatable.dart';

/// Événements du BLoC offline-first du module Classe (CF2/CF3/CF4).
sealed class ClassroomOfflineEvent extends Equatable {
  const ClassroomOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Pull delta des classes (CF2) : à déclencher au démarrage / retour online.
class ClassroomsSyncRequested extends ClassroomOfflineEvent {
  final String academicYearId;

  const ClassroomsSyncRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

/// Lecture offline des classes + compteurs (CF3), niveau optionnel.
class OfflineClassroomsRequested extends ClassroomOfflineEvent {
  final String academicYearId;
  final String? schoolLevelId;

  const OfflineClassroomsRequested({
    required this.academicYearId,
    this.schoolLevelId,
  });

  @override
  List<Object?> get props => [academicYearId, schoolLevelId];
}

/// Roster ACTIVE d'une classe (CF3) ; `query` optionnel → recherche locale.
class OfflineRosterRequested extends ClassroomOfflineEvent {
  final String classroomId;
  final String? query;

  const OfflineRosterRequested({required this.classroomId, this.query});

  @override
  List<Object?> get props => [classroomId, query];
}

/// Rosters composés de toutes les classes d'un niveau (CF4) : affichage
/// optimiste de l'écran d'organisation (transferts pending reflétés en place).
class OfflineLevelRostersRequested extends ClassroomOfflineEvent {
  final String academicYearId;
  final String schoolLevelId;

  const OfflineLevelRostersRequested({
    required this.academicYearId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [academicYearId, schoolLevelId];
}

/// Transfert d'élève OFFLINE (CF4, ADR-004 amendé) : événement local + outbox,
/// flush opportuniste. Composition à la lecture (aucune écriture du miroir).
class MemberTransferRequested extends ClassroomOfflineEvent {
  final String studentId;
  final String fromClassroomId;
  final String toClassroomId;
  final String schoolLevelId;
  final String academicYearId;
  final String? reason;

  const MemberTransferRequested({
    required this.studentId,
    required this.fromClassroomId,
    required this.toClassroomId,
    required this.schoolLevelId,
    required this.academicYearId,
    this.reason,
  });

  @override
  List<Object?> get props => [
    studentId,
    fromClassroomId,
    toClassroomId,
    schoolLevelId,
    academicYearId,
    reason,
  ];
}

/// Affectation d'un élève **non réparti** ONLINE (distribution, ADR-004) : un
/// non-réparti n'existe pas dans le miroir offline → ce geste ne peut pas être
/// un événement de transfert. Il passe par le PUT serveur + re-pull local.
class MemberReassignRequested extends ClassroomOfflineEvent {
  final String classroomMemberId;
  final String targetClassroomId;
  final String academicYearId;

  const MemberReassignRequested({
    required this.classroomMemberId,
    required this.targetClassroomId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [
    classroomMemberId,
    targetClassroomId,
    academicYearId,
  ];
}
