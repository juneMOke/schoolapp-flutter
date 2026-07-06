import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';

/// DTO delta d'une classe (CF2) : sert à la fois de modèle de transport (pull
/// `GET /sync/classrooms`, `fromJson`) et de ligne sqflite (`toMap`/`fromMap`)
/// pour `ref_classrooms`. Parsing manuel (tolérant) — pas de build_runner.
class ClassroomDto extends Equatable {
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

  const ClassroomDto({
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
  });

  static int _asInt(Object? v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Depuis la réponse de pull (JSON serveur).
  factory ClassroomDto.fromJson(Map<String, dynamic> json) => ClassroomDto(
    id: json['id'] as String,
    academicYearId: json['academicYearId'] as String,
    schoolLevelGroupId: json['schoolLevelGroupId'] as String?,
    schoolLevelId: json['schoolLevelId'] as String?,
    name: json['name'] as String,
    capacity: _asIntOrNull(json['capacity']),
    grilleId: json['grilleId'] as String?,
    teacherId: json['teacherId'] as String?,
    teacherFirstName: json['teacherFirstName'] as String?,
    teacherLastName: json['teacherLastName'] as String?,
    teacherMiddleName: json['teacherMiddleName'] as String?,
    totalCount: _asInt(json['totalCount']),
    femaleCount: _asInt(json['femaleCount']),
    maleCount: _asInt(json['maleCount']),
    version: _asIntOrNull(json['version']),
    updatedAt: _asIntOrNull(json['updatedAt']),
  );

  /// Depuis une ligne sqflite `ref_classrooms`.
  factory ClassroomDto.fromMap(Map<String, Object?> map) => ClassroomDto(
    id: map['id'] as String,
    academicYearId: map['academic_year_id'] as String,
    schoolLevelGroupId: map['school_level_group_id'] as String?,
    schoolLevelId: map['school_level_id'] as String?,
    name: map['name'] as String,
    capacity: _asIntOrNull(map['capacity']),
    grilleId: map['grille_id'] as String?,
    teacherId: map['teacher_id'] as String?,
    teacherFirstName: map['teacher_first_name'] as String?,
    teacherLastName: map['teacher_last_name'] as String?,
    teacherMiddleName: map['teacher_middle_name'] as String?,
    totalCount: _asInt(map['total_count']),
    femaleCount: _asInt(map['female_count']),
    maleCount: _asInt(map['male_count']),
    version: _asIntOrNull(map['version']),
    updatedAt: _asIntOrNull(map['updated_at']),
  );

  /// Ligne sqflite `ref_classrooms`. `synced_at` posé par le DAO à l'upsert.
  Map<String, Object?> toMap({int? syncedAt}) => <String, Object?>{
    'id': id,
    'academic_year_id': academicYearId,
    'school_level_group_id': schoolLevelGroupId,
    'school_level_id': schoolLevelId,
    'name': name,
    'capacity': capacity,
    'grille_id': grilleId,
    'teacher_id': teacherId,
    'teacher_first_name': teacherFirstName,
    'teacher_last_name': teacherLastName,
    'teacher_middle_name': teacherMiddleName,
    'total_count': totalCount,
    'female_count': femaleCount,
    'male_count': maleCount,
    'version': version,
    'updated_at': updatedAt,
    'synced_at': ?syncedAt,
  };

  OfflineClassroom toEntity({int? syncedAt}) => OfflineClassroom(
    id: id,
    academicYearId: academicYearId,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    name: name,
    capacity: capacity,
    grilleId: grilleId,
    teacherId: teacherId,
    teacherFirstName: teacherFirstName,
    teacherLastName: teacherLastName,
    teacherMiddleName: teacherMiddleName,
    totalCount: totalCount,
    femaleCount: femaleCount,
    maleCount: maleCount,
    version: version,
    updatedAt: updatedAt,
    syncedAt: syncedAt,
  );

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
  ];
}
