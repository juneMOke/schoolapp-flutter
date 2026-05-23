import 'package:equatable/equatable.dart';

class DisciplinaryStudentDetailIntent extends Equatable {
  final String studentId;
  final String studentFirstName;
  final String studentLastName;
  final String? studentMiddleName;
  final String studentGender;
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

  DisciplinaryStudentDetailIntent withRouteParams({
    required String studentId,
    required String academicYearId,
  }) => DisciplinaryStudentDetailIntent(
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender,
    academicYearId: academicYearId,
    levelName: levelName,
    levelGroupName: levelGroupName,
    classroomName: classroomName,
  );

  static DisciplinaryStudentDetailIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is DisciplinaryStudentDetailIntent) {
      return extra.withRouteParams(
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }

    return DisciplinaryStudentDetailIntent.invalid(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

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
