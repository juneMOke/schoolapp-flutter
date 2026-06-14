import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

class DisciplinaryCaseSummary extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final StudentGender studentGender;
  final String academicYearId;
  final String title;
  final DisciplinaryCaseStatus status;
  final String content;
  final DisciplinaryCategory category;
  final DisciplinarySeverity severity;
  final DisciplinarySanction sanction;
  final DateTime? createdAt;

  const DisciplinaryCaseSummary({
    required this.id,
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.academicYearId,
    required this.title,
    required this.status,
    required this.content,
    required this.category,
    required this.severity,
    required this.sanction,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    academicYearId,
    title,
    status,
    content,
    category,
    severity,
    sanction,
    createdAt,
  ];
}
