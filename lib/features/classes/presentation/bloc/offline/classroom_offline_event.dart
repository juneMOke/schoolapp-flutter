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

/// Déplacement d'élève ONLINE (CF4 Option A) : PUT serveur + re-pull local.
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
