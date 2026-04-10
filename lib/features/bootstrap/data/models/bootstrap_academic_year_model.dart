import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_academic_year.dart';

class BootstrapAcademicYearModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool current;

  const BootstrapAcademicYearModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  factory BootstrapAcademicYearModel.fromJson(Map<String, dynamic> json) {
    return BootstrapAcademicYearModel(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      current: json['current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'current': current,
  };

  BootstrapAcademicYear toEntity() {
    return BootstrapAcademicYear(
      id: id,
      name: name,
      startDate: startDate,
      endDate: endDate,
      current: current,
    );
  }
}
