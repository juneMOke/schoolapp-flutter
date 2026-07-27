import 'package:equatable/equatable.dart';

/// Bilan agrégé de la synchro des classes (CF2) : orchestre deux flux keyset
/// **indépendants** (`classrooms` + `classroom-members`, curseurs propres à
/// chacun — pas de curseur unique agrégeable ici). `notModified` = les deux
/// flux étaient déjà à jour (304 honoré des deux côtés).
class ClassroomSyncOutcome extends Equatable {
  final int classroomsUpserted;
  final int membersUpserted;
  final bool notModified;
  final int syncedAt;

  const ClassroomSyncOutcome({
    required this.classroomsUpserted,
    required this.membersUpserted,
    required this.notModified,
    required this.syncedAt,
  });

  @override
  List<Object?> get props => [
    classroomsUpserted,
    membersUpserted,
    notModified,
    syncedAt,
  ];
}
