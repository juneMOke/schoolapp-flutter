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
  final int page;
  final int size;

  const EnrollmentSummariesRequested({
    required this.status,
    required this.academicYearId,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [status, academicYearId, page, size];
}

class EnrollmentSummariesByStudentNameRequested extends EnrollmentEvent {
  final String status;
  final String academicYearId;
  final String firstName;
  final String lastName;
  final String surname;
  final int page;
  final int size;

  const EnrollmentSummariesByStudentNameRequested({
    required this.status,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    firstName,
    lastName,
    surname,
    page,
    size,
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
  final int page;
  final int size;

  const EnrollmentSummariesByStudentNamesAndDateOfBirthRequested({
    required this.status,
    required this.academicYearId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    page,
    size,
  ];
}

class EnrollmentSummariesByDateOfBirthRequested extends EnrollmentEvent {
  final String status;
  final String academicYearId;
  final String dateOfBirth;
  final int page;
  final int size;

  const EnrollmentSummariesByDateOfBirthRequested({
    required this.status,
    required this.academicYearId,
    required this.dateOfBirth,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [status, academicYearId, dateOfBirth, page, size];
}

class EnrollmentSummariesByAcademicInfoRequested extends EnrollmentEvent {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final int page;
  final int size;

  const EnrollmentSummariesByAcademicInfoRequested({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    surname,
    schoolLevelGroupId,
    schoolLevelId,
    page,
    size,
  ];
}

class EnrollmentSummariesPageRequested extends EnrollmentEvent {
  final int page;

  const EnrollmentSummariesPageRequested({required this.page});

  @override
  List<Object?> get props => [page];
}

class EnrollmentDetailRequested extends EnrollmentEvent {
  final String enrollmentId;

  /// Lorsque [silent] est vrai, le bloc ne passe pas par l'état [loading],
  /// ce qui évite de détruire le stepper (et de perdre l'étape courante).
  final bool silent;

  const EnrollmentDetailRequested({
    required this.enrollmentId,
    this.silent = false,
  });

  @override
  List<Object?> get props => [enrollmentId, silent];
}

class EnrollmentNewDetailInitialized extends EnrollmentEvent {
  const EnrollmentNewDetailInitialized();
}

class EnrollmentCreateRequested extends EnrollmentEvent {
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String birthPlace;
  final String nationality;
  final String gender;

  const EnrollmentCreateRequested({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.birthPlace,
    required this.nationality,
    required this.gender,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    surname,
    dateOfBirth,
    birthPlace,
    nationality,
    gender,
  ];
}

class EnrollmentCreateResultConsumed extends EnrollmentEvent {
  const EnrollmentCreateResultConsumed();
}

class EnrollmentStatusUpdateRequested extends EnrollmentEvent {
  final String enrollmentId;
  final String status;

  const EnrollmentStatusUpdateRequested({
    required this.enrollmentId,
    required this.status,
  });

  @override
  List<Object?> get props => [enrollmentId, status];
}

class EnrollmentStatusUpdateResultConsumed extends EnrollmentEvent {
  const EnrollmentStatusUpdateResultConsumed();
}

class EnrollmentPreviewByStudentIdRequested extends EnrollmentEvent {
  final String studentId;
  final bool silent;

  const EnrollmentPreviewByStudentIdRequested({
    required this.studentId,
    this.silent = false,
  });

  @override
  List<Object?> get props => [studentId, silent];
}
