import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';

class SchoolLevelModel {
  final String id;
  final String name;
  final String levelGroupId;
  final String academicYearId;
  final String? description;

  const SchoolLevelModel({
    required this.id,
    required this.name,
    required this.levelGroupId,
    required this.academicYearId,
    this.description,
  });

  factory SchoolLevelModel.fromJson(Map<String, dynamic> json) =>
      SchoolLevelModel(
        id: json['id'] as String,
        name: json['name'] as String,
        levelGroupId: json['levelGroupId'] as String,
        academicYearId: json['academicYearId'] as String,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'levelGroupId': levelGroupId,
    'academicYearId': academicYearId,
    'description': description,
  };

  SchoolLevel toSchoolLevel() => SchoolLevel(
    id: id,
    name: name,
    levelGroupId: levelGroupId,
    academicYearId: academicYearId,
    description: description,
  );
}
