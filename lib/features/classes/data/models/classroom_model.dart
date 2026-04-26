import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';

part 'classroom_model.g.dart';

@JsonSerializable()
class ClassroomModel extends Equatable {
  final String id;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String academicYearId;
  final String name;
  final int capacity;
  final String? teacherId;
  final String? teacherFirstName;
  final String? teacherLastName;
  final String? teacherMiddleName;
  final int totalCount;
  final int femaleCount;
  final int maleCount;

  const ClassroomModel({
    required this.id,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.academicYearId,
    required this.name,
    required this.capacity,
    this.teacherId,
    this.teacherFirstName,
    this.teacherLastName,
    this.teacherMiddleName,
    required this.totalCount,
    required this.femaleCount,
    required this.maleCount,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    final model = _$ClassroomModelFromJson(json);
    _validateRequiredField(model.id, 'id');
    _validateRequiredField(model.schoolLevelGroupId, 'schoolLevelGroupId');
    _validateRequiredField(model.schoolLevelId, 'schoolLevelId');
    _validateRequiredField(model.academicYearId, 'academicYearId');
    _validateRequiredField(model.name, 'name');
    return model;
  }

  static void _validateRequiredField(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw FormatException('Invalid classroom payload: $fieldName is empty');
    }
  }

  Map<String, dynamic> toJson() => _$ClassroomModelToJson(this);

  Classroom toEntity() => Classroom(
    id: id,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    academicYearId: academicYearId,
    name: name,
    capacity: capacity,
    teacherId: teacherId,
    teacherFirstName: teacherFirstName,
    teacherLastName: teacherLastName,
    teacherMiddleName: teacherMiddleName,
    totalCount: totalCount,
    femaleCount: femaleCount,
    maleCount: maleCount,
  );

  @override
  List<Object?> get props => [
    id,
    schoolLevelGroupId,
    schoolLevelId,
    academicYearId,
    name,
    capacity,
    teacherId,
    teacherFirstName,
    teacherLastName,
    teacherMiddleName,
    totalCount,
    femaleCount,
    maleCount,
  ];
}
