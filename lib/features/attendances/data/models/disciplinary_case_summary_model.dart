import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

part 'disciplinary_case_summary_model.g.dart';

@JsonSerializable()
class DisciplinaryCaseSummaryModel extends Equatable {
  final String id;
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  final String academicYearId;
  final String title;
  final String status;
  final String content;

  // Nouveaux champs (DTO). Nullables par resilience au deploiement backend :
  // l'entite retombe sur `unknown` si la valeur est absente ou inconnue.
  final String? category;
  final String? severity;
  final String? sanction;
  final DateTime? createdAt;

  const DisciplinaryCaseSummaryModel({
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
    this.category,
    this.severity,
    this.sanction,
    this.createdAt,
  });

  factory DisciplinaryCaseSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DisciplinaryCaseSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$DisciplinaryCaseSummaryModelToJson(this);

  DisciplinaryCaseSummary toEntity() => DisciplinaryCaseSummary(
    id: id,
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: StudentGenderX.fromApiValue(studentGender),
    academicYearId: academicYearId,
    title: title,
    status: DisciplinaryCaseStatusX.fromApiValue(status),
    content: content,
    category: DisciplinaryCategoryX.fromApiValue(category),
    severity: DisciplinarySeverityX.fromApiValue(severity),
    sanction: DisciplinarySanctionX.fromApiValue(sanction),
    createdAt: createdAt,
  );

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
