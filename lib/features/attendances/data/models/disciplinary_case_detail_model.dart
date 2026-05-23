import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

part 'disciplinary_case_detail_model.g.dart';

@JsonSerializable()
class DisciplinaryCaseDetailModel extends Equatable {
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

  const DisciplinaryCaseDetailModel({
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

  factory DisciplinaryCaseDetailModel.fromJson(Map<String, dynamic> json) =>
      _$DisciplinaryCaseDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$DisciplinaryCaseDetailModelToJson(this);

  DisciplinaryCaseDetail toEntity() => DisciplinaryCaseDetail(
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
