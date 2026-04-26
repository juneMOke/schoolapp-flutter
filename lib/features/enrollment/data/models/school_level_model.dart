import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';

class SchoolLevelModel {
  final String id;
  final String name;
  final String code;
  final int displayOrder;
  final bool splitIntoClassrooms;

  const SchoolLevelModel({
    required this.id,
    required this.name,
    required this.code,
    required this.displayOrder,
    required this.splitIntoClassrooms,
  });

  factory SchoolLevelModel.fromJson(Map<String, dynamic> json) =>
      SchoolLevelModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        displayOrder: json['displayOrder'] as int,
        splitIntoClassrooms: json['splitIntoClassrooms'] as bool,
      );

  SchoolLevel toSchoolLevel() => SchoolLevel(
    id: id,
    name: name,
    code: code,
    displayOrder: displayOrder,
    splitIntoClassrooms: splitIntoClassrooms,
  );
}
