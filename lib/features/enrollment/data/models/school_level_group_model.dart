import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';

class SchoolLevelGroupModel {
  final String id;
  final String name;
  final String? description;

  const SchoolLevelGroupModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory SchoolLevelGroupModel.fromJson(Map<String, dynamic> json) =>
      SchoolLevelGroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'description': description,
  };

  SchoolLevelGroup toSchoolLevelGroup() => SchoolLevelGroup(
    id: id,
    name: name,
    description: description,
  );
}
