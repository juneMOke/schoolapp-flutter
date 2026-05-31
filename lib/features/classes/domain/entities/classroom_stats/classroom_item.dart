import 'package:equatable/equatable.dart';

class ClassroomItem extends Equatable {
  final String classroomId;
  final String name;
  final int totalStudents;
  final int girls;
  final int boys;

  const ClassroomItem({
    required this.classroomId,
    required this.name,
    required this.totalStudents,
    required this.girls,
    required this.boys,
  });

  @override
  List<Object?> get props => [classroomId, name, totalStudents, girls, boys];
}
