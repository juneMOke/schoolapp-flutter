import 'package:equatable/equatable.dart';

class FacturationDetailIntent extends Equatable {
  final String studentId;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String levelName;
  final String levelGroupName;

  const FacturationDetailIntent({
    required this.studentId,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.levelName,
    required this.levelGroupName,
  });

  const FacturationDetailIntent.invalid({
    required String studentId,
    required String academicYearId,
  }) : this(
         studentId: studentId,
         academicYearId: academicYearId,
         firstName: '',
         lastName: '',
         surname: '',
         levelName: '',
         levelGroupName: '',
       );

  bool get hasDisplayContext =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      levelName.trim().isNotEmpty &&
      levelGroupName.trim().isNotEmpty;

  FacturationDetailIntent withRouteParams({
    required String studentId,
    required String academicYearId,
  }) => FacturationDetailIntent(
    studentId: studentId,
    academicYearId: academicYearId,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    levelName: levelName,
    levelGroupName: levelGroupName,
  );

  static FacturationDetailIntent fromRouteContext({
    required String studentId,
    required String academicYearId,
    Object? extra,
  }) {
    if (extra is FacturationDetailIntent) {
      return extra.withRouteParams(
        studentId: studentId,
        academicYearId: academicYearId,
      );
    }

    return FacturationDetailIntent.invalid(
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  @override
  List<Object?> get props => [
    studentId,
    academicYearId,
    firstName,
    lastName,
    surname,
    levelName,
    levelGroupName,
  ];
}
