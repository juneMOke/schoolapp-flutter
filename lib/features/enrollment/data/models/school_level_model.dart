import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';

class SchoolLevelModel {
  final String id;
  final String name;
  final String code;
  final int displayOrder;

  const SchoolLevelModel({
    required this.id,
    required this.name,
    required this.code,
    required this.displayOrder,
  });

  factory SchoolLevelModel.fromJson(Map<String, dynamic> json) =>
      SchoolLevelModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        displayOrder: json['displayOrder'] as int,
      );

  SchoolLevel toSchoolLevel() => SchoolLevel(
    id: id,
    name: name,
    code: code,
    displayOrder: displayOrder
  );
}
