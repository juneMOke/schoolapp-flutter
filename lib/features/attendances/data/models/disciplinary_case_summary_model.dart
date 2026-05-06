import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
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
  ];
}
