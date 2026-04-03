import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';

class AcademicYearModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool current;

  const AcademicYearModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  factory AcademicYearModel.fromJson(Map<String, dynamic> json) =>
      AcademicYearModel(
        id: json['id'] as String,
        name: json['name'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        current: json['current'] as bool? ?? false,
      );

  AcademicYear toAcademicYear() => AcademicYear(
    id: id,
    name: name,
    startDate: startDate,
    endDate: endDate,
    current: current,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'current': current,
  };
}
