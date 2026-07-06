import 'package:equatable/equatable.dart';

/// Classe telle que lue localement (offline-first, CF3).
///
/// Distincte de [Classroom] (online) : les champs de niveau, la capacité et la
/// grille sont **nullables** (CF1), et l'entité porte `version`/`updatedAt`
/// (delta-sync / optimistic lock) ainsi que `syncedAt` (fraîcheur ADR-002).
///
/// ⚠️ Compteurs pré-agrégés serveur : ne jamais supposer
/// `totalCount == femaleCount + maleCount` (le genre OTHER est inclus dans
/// `totalCount` sans compteur dédié).
class OfflineClassroom extends Equatable {
  final String id;
  final String academicYearId;
  final String? schoolLevelGroupId;
  final String? schoolLevelId;
  final String name;
  final int? capacity;
  final String? grilleId;
  final String? teacherId;
  final String? teacherFirstName;
  final String? teacherLastName;
  final String? teacherMiddleName;
  final int totalCount;
  final int femaleCount;
  final int maleCount;
  final int? version;
  final int? updatedAt;
  final int? syncedAt;

  const OfflineClassroom({
    required this.id,
    required this.academicYearId,
    this.schoolLevelGroupId,
    this.schoolLevelId,
    required this.name,
    this.capacity,
    this.grilleId,
    this.teacherId,
    this.teacherFirstName,
    this.teacherLastName,
    this.teacherMiddleName,
    this.totalCount = 0,
    this.femaleCount = 0,
    this.maleCount = 0,
    this.version,
    this.updatedAt,
    this.syncedAt,
  });

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    schoolLevelGroupId,
    schoolLevelId,
    name,
    capacity,
    grilleId,
    teacherId,
    teacherFirstName,
    teacherLastName,
    teacherMiddleName,
    totalCount,
    femaleCount,
    maleCount,
    version,
    updatedAt,
    syncedAt,
  ];
}
