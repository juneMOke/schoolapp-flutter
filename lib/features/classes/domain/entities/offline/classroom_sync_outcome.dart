import 'package:equatable/equatable.dart';

/// Bilan d'un pull delta des classes (CF2). `notModified` = 304 honoré (aucune
/// écriture, curseur conservé, seule la fraîcheur est rafraîchie).
class ClassroomSyncOutcome extends Equatable {
  final int classroomsUpserted;
  final int membersUpserted;
  final bool notModified;
  final int syncedAt;
  final int? cursor;

  const ClassroomSyncOutcome({
    required this.classroomsUpserted,
    required this.membersUpserted,
    required this.notModified,
    required this.syncedAt,
    this.cursor,
  });

  const ClassroomSyncOutcome.notModifiedAt(int syncedAt, int? cursor)
    : this(
        classroomsUpserted: 0,
        membersUpserted: 0,
        notModified: true,
        syncedAt: syncedAt,
        cursor: cursor,
      );

  @override
  List<Object?> get props => [
    classroomsUpserted,
    membersUpserted,
    notModified,
    syncedAt,
    cursor,
  ];
}
