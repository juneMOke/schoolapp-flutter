import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_summary.dart';

class StudentSummaryModel {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;

  const StudentSummaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
  });

  factory StudentSummaryModel.fromJson(Map<String, dynamic> json) =>
      StudentSummaryModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        surname: json['surname'] as String,
        dateOfBirth: json['dateOfBirth'] as String,
        gender: json['gender'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
  };

  StudentSummary toStudentSummary() => StudentSummary(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    gender: Gender.fromString(gender),
  );
}
