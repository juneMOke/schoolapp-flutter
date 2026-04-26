import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
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

  const Classroom({
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
