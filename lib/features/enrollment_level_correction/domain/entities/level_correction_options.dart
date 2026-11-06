import 'package:equatable/equatable.dart';

/// Un niveau que la correction peut viser, avec son cycle.
class LevelOption extends Equatable {
  final String id;
  final String name;
  final String groupId;
  final String groupName;

  const LevelOption({
    required this.id,
    required this.name,
    required this.groupId,
    required this.groupName,
  });

  @override
  List<Object?> get props => [id, name, groupId, groupName];
}

/// Une classe de l'année, rattachée à son niveau.
class ClassroomOption extends Equatable {
  final String id;
  final String name;
  final String? schoolLevelId;

  const ClassroomOption({
    required this.id,
    required this.name,
    this.schoolLevelId,
  });

  @override
  List<Object?> get props => [id, name, schoolLevelId];
}

/// Ce que la tablette sait pour proposer une correction : les classes de
/// l'année et la classe actuelle de l'élève.
class LevelCorrectionClassrooms extends Equatable {
  final List<ClassroomOption> classrooms;

  /// `null` : l'élève n'est dans aucune classe.
  final String? currentClassroomId;

  const LevelCorrectionClassrooms({
    required this.classrooms,
    this.currentClassroomId,
  });

  bool get isInClassroom => currentClassroomId != null;

  List<ClassroomOption> ofLevel(String levelId) => [
    for (final c in classrooms)
      if (c.schoolLevelId == levelId) c,
  ];

  /// D3 : un élève déjà en classe, vers un niveau qui a au moins une classe,
  /// doit en recevoir une. Sinon il resterait dans une classe d'un autre
  /// niveau, ce que le modèle interdit.
  bool requiresClassroom(String levelId) =>
      isInClassroom && ofLevel(levelId).isNotEmpty;

  @override
  List<Object?> get props => [classrooms, currentClassroomId];
}
