import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

part 'create_disciplinary_case_request_model.g.dart';

@JsonSerializable()
class CreateDisciplinaryCaseRequestModel extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  @JsonKey(
    fromJson: DateOnlyJsonHelper.fromJson,
    toJson: DateOnlyJsonHelper.toJson,
  )
  final DateTime disciplinaryCaseDate;
  final String academicYearId;
  final String title;
  final String content;

  const CreateDisciplinaryCaseRequestModel({
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

  factory CreateDisciplinaryCaseRequestModel.fromDomain({
    required String studentId,
    required String studentFirstName,
    required String studentLastName,
    String? studentMiddleName,
    required StudentGender studentGender,
    required DateTime disciplinaryCaseDate,
    required String academicYearId,
    required String title,
    required String content,
  }) => CreateDisciplinaryCaseRequestModel(
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender.toApiValue(),
    disciplinaryCaseDate: disciplinaryCaseDate,
    academicYearId: academicYearId,
    title: title,
    content: content,
  );

  factory CreateDisciplinaryCaseRequestModel.fromJson(
    Map<String, dynamic> json,
  ) => _$CreateDisciplinaryCaseRequestModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$CreateDisciplinaryCaseRequestModelToJson(this);

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
