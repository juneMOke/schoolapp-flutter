import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';

class BootstrapClassroomModel {
  final String id;
  final int version;
  final String schoolLevelId;
  final String name;
  final int capacity;
  final int totalCount;
  final int femaleCount;
  final int maleCount;

  const BootstrapClassroomModel({
    required this.id,
    required this.version,
    required this.schoolLevelId,
    required this.name,
    required this.capacity,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
  });

  factory BootstrapClassroomModel.fromJson(Map<String, dynamic> json) {
    return BootstrapClassroomModel(
      id: json['id'] as String,
      version: json['version'] as int? ?? 0,
      schoolLevelId: json['schoolLevelId'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      femaleCount: json['femaleCount'] as int? ?? 0,
      maleCount: json['maleCount'] as int? ?? 0,
    );
  }

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

  BootstrapClassroom toEntity() {
    return BootstrapClassroom(
      id: id,
      version: version,
      schoolLevelId: schoolLevelId,
      name: name,
      capacity: capacity,
      totalCount: totalCount,
      femaleCount: femaleCount,
      maleCount: maleCount,
    );
  }
}
