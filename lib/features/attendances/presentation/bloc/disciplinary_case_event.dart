import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

sealed class DisciplinaryCaseEvent extends Equatable {
  const DisciplinaryCaseEvent();
}

class DisciplinaryCaseListRequested extends DisciplinaryCaseEvent {
  final String studentId;
  final String academicYearId;

  const DisciplinaryCaseListRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

class DisciplinaryCaseDetailRequested extends DisciplinaryCaseEvent {
  final String caseId;

  const DisciplinaryCaseDetailRequested({required this.caseId});

  @override
  List<Object?> get props => [caseId];
}

class DisciplinaryCaseCreateRequested extends DisciplinaryCaseEvent {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final DateTime disciplinaryCaseDate;
  final String academicYearId;
  final String title;
  final String content;

  const DisciplinaryCaseCreateRequested({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.disciplinaryCaseDate,
    required this.academicYearId,
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    disciplinaryCaseDate,
    academicYearId,
    title,
    content,
  ];
}

class DisciplinaryCaseCreateStatusResetRequested extends DisciplinaryCaseEvent {
  const DisciplinaryCaseCreateStatusResetRequested();

  @override
  List<Object?> get props => [];
}

class DisciplinaryCaseResetRequested extends DisciplinaryCaseEvent {
  const DisciplinaryCaseResetRequested();

  @override
  List<Object?> get props => [];
}
