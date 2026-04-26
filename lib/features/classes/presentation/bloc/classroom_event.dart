import 'package:equatable/equatable.dart';

sealed class ClassroomEvent extends Equatable {
  const ClassroomEvent();
}

class ClassroomRequested extends ClassroomEvent {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String academicYearId;

  const ClassroomRequested({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [
    schoolLevelGroupId,
    schoolLevelId,
    academicYearId,
  ];
}

class ClassroomResetRequested extends ClassroomEvent {
  const ClassroomResetRequested();

  @override
  List<Object?> get props => [];
}
