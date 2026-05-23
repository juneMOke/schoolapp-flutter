import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_classroom.dart';

class AttendanceCycleOption extends Equatable {
  final String id;
  final String label;
  final int displayOrder;
  final List<AttendanceLevelOption> levels;

  const AttendanceCycleOption({
    required this.id,
    required this.label,
    required this.displayOrder,
    required this.levels,
  });

  @override
  List<Object?> get props => [id, label, displayOrder, levels];
}

class AttendanceLevelOption extends Equatable {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;
  final int displayOrder;
  final List<BootstrapClassroom> classrooms;

  const AttendanceLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
    required this.displayOrder,
    required this.classrooms,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    label,
    displayOrder,
    classrooms,
  ];
}

class AttendanceSearchRequest extends Equatable {
  final AttendanceCycleOption selectedCycle;
  final AttendanceLevelOption selectedLevel;
  final BootstrapClassroom selectedClassroom;
  final DateTime date;

  const AttendanceSearchRequest({
    required this.selectedCycle,
    required this.selectedLevel,
    required this.selectedClassroom,
    required this.date,
  });

  @override
  List<Object?> get props => [selectedCycle, selectedLevel, selectedClassroom, date];
}

class AttendanceStats extends Equatable {
  final int total;
  final int girls;
  final int boys;

  const AttendanceStats({
    required this.total,
    required this.girls,
    required this.boys,
  });

  factory AttendanceStats.fromRecords(List<AttendanceRecord> records) {
    var girls = 0;
    var boys = 0;

    for (final record in records) {
      switch (record.studentGender) {
        case StudentGender.female:
          girls += 1;
          break;
        case StudentGender.male:
          boys += 1;
          break;
        case StudentGender.other:
          break;
      }
    }

    return AttendanceStats(total: records.length, girls: girls, boys: boys);
  }

  @override
  List<Object?> get props => [total, girls, boys];
}