import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';

/// Une ligne de [StudentIdentityDao] : l'élève, joint à son inscription de
/// l'année quand elle existe.
class StudentIdentityRow {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String? gender;
  final String? levelName;
  final String? levelGroupName;

  const StudentIdentityRow({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    this.gender,
    this.levelName,
    this.levelGroupName,
  });

  factory StudentIdentityRow.fromMap(Map<String, Object?> row) =>
      StudentIdentityRow(
        studentId: row['id'] as String,
        firstName: (row['first_name'] as String?) ?? '',
        lastName: (row['last_name'] as String?) ?? '',
        surname: row['surname'] as String?,
        gender: row['gender'] as String?,
        levelName: row['level_name'] as String?,
        levelGroupName: row['level_group_name'] as String?,
      );

  StudentIdentity toEntity() => StudentIdentity(
    studentId: studentId,
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    surname: surname?.trim() ?? '',
    gender: gender?.trim().toUpperCase() ?? '',
    levelName: levelName?.trim() ?? '',
    levelGroupName: levelGroupName?.trim() ?? '',
  );
}
