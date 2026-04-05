part of 'student_bloc.dart';

sealed class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class StudentStateReset extends StudentEvent {
  const StudentStateReset();
}

class StudentPersonalInfoUpdateRequested extends StudentEvent {
  final String studentId;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;
  final String birthPlace;
  final String nationality;

  const StudentPersonalInfoUpdateRequested({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    required this.birthPlace,
    required this.nationality,
  });

  @override
  List<Object?> get props => [
        studentId,
        firstName,
        lastName,
        surname,
        dateOfBirth,
        gender,
        birthPlace,
        nationality,
      ];
}
