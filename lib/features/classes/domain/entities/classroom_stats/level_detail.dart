import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/classroom_item.dart';

class LevelDetail extends Equatable {
  final String levelId;
  final String levelCode;
  final int totalStudents;
  final int girls;
  final int boys;
  final List<ClassroomItem> classrooms;

  const LevelDetail({
    required this.levelId,
    required this.levelCode,
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.classrooms,
  });

  @override
  List<Object?> get props => [
    levelId,
    levelCode,
    totalStudents,
    girls,
    boys,
    classrooms,
  ];
}
