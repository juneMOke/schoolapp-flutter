import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/day_enrollment_entry.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';

class DayEnrollmentEntryModel {
  final String enrollmentId;
  final String studentId;
  final String firstName;
  final String lastName;
  final String surname;
  final String gender;
  final String schoolLevelId;
  final String schoolLevel;
  final String cycle;
  final bool formerStudent;
  final String enrollmentDate;
  final String createdAt;
  final String? recordedBy;

  const DayEnrollmentEntryModel({
    required this.enrollmentId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gender,
    required this.schoolLevelId,
    required this.schoolLevel,
    required this.cycle,
    required this.formerStudent,
    required this.enrollmentDate,
    required this.createdAt,
    this.recordedBy,
  });

  factory DayEnrollmentEntryModel.fromJson(Map<String, dynamic> json) {
    return DayEnrollmentEntryModel(
      enrollmentId: json['enrollmentId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      gender: json['gender'] as String? ?? 'MALE',
      schoolLevelId: json['schoolLevelId'] as String? ?? '',
      schoolLevel: json['schoolLevel'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      formerStudent: json['formerStudent'] as bool? ?? false,
      enrollmentDate: json['enrollmentDate'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      // Nul quand l'annuaire ne résout pas. Le repli est `null`, PAS une
      // chaîne vide : l'écran doit pouvoir distinguer « pas d'agent connu »
      // d'un nom vide, pour afficher un tiret plutôt que rien.
      recordedBy: json['recordedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enrollmentId': enrollmentId,
    'studentId': studentId,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'gender': gender,
    'schoolLevelId': schoolLevelId,
    'schoolLevel': schoolLevel,
    'cycle': cycle,
    'formerStudent': formerStudent,
    'enrollmentDate': enrollmentDate,
    'createdAt': createdAt,
    'recordedBy': recordedBy,
  };

  DayEnrollmentEntry toEntity() => DayEnrollmentEntry(
    enrollmentId: enrollmentId,
    studentId: studentId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    gender: Gender.fromString(gender),
    schoolLevelId: schoolLevelId,
    schoolLevel: schoolLevel,
    cycle: cycle,
    formerStudent: formerStudent,
    enrollmentDate: DateTime.tryParse(enrollmentDate) ?? DateTime(0),
    createdAt: DateTime.tryParse(createdAt) ?? DateTime(0),
    recordedBy: recordedBy,
  );
}
