import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';

/// Résumé d'une classe. Parsing **défensif** (écrit à la main, pas de
/// `@JsonSerializable`) : les compteurs absents ou `null` retombent sur 0 et les
/// chaînes sur `''`, par cohérence avec la résilience de [CourseRefModel] —
/// une seule classe mal formée (ex. `capacity` non saisie côté backend) ne doit
/// jamais faire échouer tout le payload « mes cours ».
class ClassroomSummaryModel extends Equatable {
  final String id;

  // `version` est un champ d'infrastructure (verrou optimiste) : nullable par
  // résilience au cas où le backend ne le renverrait pas.
  final int? version;
  final String schoolLevelId;
  final String name;
  final int capacity;
  final int totalCount;
  final int femaleCount;
  final int maleCount;

  const ClassroomSummaryModel({
    required this.id,
    this.version,
    required this.schoolLevelId,
    required this.name,
    required this.capacity,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
  });

  static String _str(Object? v) => (v ?? '').toString();
  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;

  factory ClassroomSummaryModel.fromJson(Map<String, dynamic> json) =>
      ClassroomSummaryModel(
        id: _str(json['id']),
        version: (json['version'] as num?)?.toInt(),
        schoolLevelId: _str(json['schoolLevelId']),
        name: _str(json['name']),
        capacity: _int(json['capacity']),
        totalCount: _int(json['totalCount']),
        femaleCount: _int(json['femaleCount']),
        maleCount: _int(json['maleCount']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'schoolLevelId': schoolLevelId,
    'name': name,
    'capacity': capacity,
    'totalCount': totalCount,
    'femaleCount': femaleCount,
    'maleCount': maleCount,
  };

  ClassroomSummary toEntity() => ClassroomSummary(
    id: id,
    version: version,
    schoolLevelId: schoolLevelId,
    name: name,
    capacity: capacity,
    totalCount: totalCount,
    femaleCount: femaleCount,
    maleCount: maleCount,
  );

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
