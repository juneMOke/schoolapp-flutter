import 'package:equatable/equatable.dart';

/// Résumé d'une classe tel que renvoyé par le module academics.
///
/// Classe dédiée au module academics : on ne réutilise pas [Classroom] du
/// module classes car la structure du résumé peut évoluer indépendamment.
class ClassroomSummary extends Equatable {
  final String id;
  final int? version;
  final String schoolLevelId;
  final String name;
  final int capacity;
  final int totalCount;
  final int femaleCount;
  final int maleCount;

  const ClassroomSummary({
    required this.id,
    this.version,
    required this.schoolLevelId,
    required this.name,
    required this.capacity,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
  });

  @override
  List<Object?> get props => [
    id,
    version,
    schoolLevelId,
    name,
    capacity,
    totalCount,
    femaleCount,
    maleCount,
  ];
}
