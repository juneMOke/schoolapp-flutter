part of 'enrollment_bloc.dart';

sealed class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();

  @override
  List<Object?> get props => [];
}

class EnrollmentResetRequested extends EnrollmentEvent {
  const EnrollmentResetRequested();
}

class EnrollmentSummariesRefreshRequested extends EnrollmentEvent {
  const EnrollmentSummariesRefreshRequested();
}

class EnrollmentSummariesRequested extends EnrollmentEvent {
  final String status;
  final String academicYearId;

  const EnrollmentSummariesRequested({
    required this.status,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [status, academicYearId];
}

class EnrollmentSummariesByStudentNameRequested extends EnrollmentEvent {
  final String status;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;

  const EnrollmentSummariesByStudentNameRequested({
    required this.status,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    firstName,
    lastName,
    surname,
  ];
}

class EnrollmentSummariesByStudentNamesAndDateOfBirthRequested
    extends EnrollmentEvent {
  final String status;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;

  const EnrollmentSummariesByStudentNamesAndDateOfBirthRequested({
    required this.status,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    firstName,
    lastName,
    surname,
    dateOfBirth,
  ];
}

class EnrollmentSummariesByDateOfBirthRequested extends EnrollmentEvent {
  final String status;
  final String academicYearId;
  final String dateOfBirth;

  const EnrollmentSummariesByDateOfBirthRequested({
    required this.status,
    required this.academicYearId,
    required this.dateOfBirth,
  });

  @override
  List<Object?> get props => [status, academicYearId, dateOfBirth];
}

class EnrollmentDetailRequested extends EnrollmentEvent {
  final String enrollmentId;

  const EnrollmentDetailRequested({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}
