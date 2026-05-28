import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

class ClassroomWithMembers extends Equatable {
  final Classroom classroom;
  final List<ClassroomMember> members;

  const ClassroomWithMembers({required this.classroom, required this.members});

  @override
  List<Object?> get props => [classroom, members];
}
