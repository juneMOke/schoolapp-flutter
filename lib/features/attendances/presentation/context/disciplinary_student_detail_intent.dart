import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/navigation/student_record_intent.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_identity.dart';

class DisciplinaryStudentDetailIntent extends Equatable
    implements StudentRecordIntent {
  @override
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
  @override
  final String academicYearId;
  final String levelName;
  final String levelGroupName;
  final String classroomName;

  const DisciplinaryStudentDetailIntent({
    required this.studentId,
    required this.studentFirstName,
    required this.studentLastName,
    this.studentMiddleName,
    required this.studentGender,
    required this.academicYearId,
    required this.levelName,
    required this.levelGroupName,
    this.classroomName = '',
  });

  const DisciplinaryStudentDetailIntent.invalid({
    required String studentId,
    required String academicYearId,
  }) : this(
         studentId: studentId,
         studentFirstName: '',
         studentLastName: '',
         studentMiddleName: null,
         studentGender: '',
         academicYearId: academicYearId,
         levelName: '',
         levelGroupName: '',
         classroomName: '',
       );

  bool get hasDisplayContext =>
      studentFirstName.trim().isNotEmpty && studentLastName.trim().isNotEmpty;

  /// Le dossier rouvert par son adresse : l'identité relue en base locale
  /// remplace celle que la navigation n'a pas pu passer. La salle de classe
  /// n'y figure pas : elle ne sert qu'au sur-titre.
  DisciplinaryStudentDetailIntent withIdentity(StudentIdentity identity) =>
      DisciplinaryStudentDetailIntent(
        studentId: studentId,
        studentFirstName: identity.firstName,
        studentLastName: identity.lastName,
        studentMiddleName: identity.surname.isEmpty ? null : identity.surname,
        studentGender: identity.gender,
        academicYearId: academicYearId,
        levelName: identity.levelName,
        levelGroupName: identity.levelGroupName,
      );

  static DisciplinaryStudentDetailIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) =>
      extraForRecord<DisciplinaryStudentDetailIntent>(
        extra,
        studentId: studentId,
        academicYearId: academicYearId,
      ) ??
      DisciplinaryStudentDetailIntent.invalid(
        studentId: studentId,
        academicYearId: academicYearId,
      );

  @override
  List<Object?> get props => [
    studentId,
    studentFirstName,
    studentLastName,
    studentMiddleName,
    studentGender,
    academicYearId,
    levelName,
    levelGroupName,
    classroomName,
  ];
}
