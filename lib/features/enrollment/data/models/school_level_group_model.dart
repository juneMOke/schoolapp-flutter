import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';

class SchoolLevelGroupModel {
  final String id;
  final String name;
  final String code;

  const SchoolLevelGroupModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory SchoolLevelGroupModel.fromJson(Map<String, dynamic> json) =>
      SchoolLevelGroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['description'] as String,
      );

  SchoolLevelGroup toSchoolLevelGroup() =>
      SchoolLevelGroup(id: id, name: name, code: code);
}
