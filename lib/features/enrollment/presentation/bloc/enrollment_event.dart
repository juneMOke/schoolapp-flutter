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

// NB : les événements d'ÉCRITURE online (création, avancement de statut) ont
// été retirés avec la convergence offline-first — toute écriture passe par le
// brouillon local (EnrollmentOfflineBloc) puis un agrégat outbox. Ce bloc ne
// sert plus que les LECTURES online (listes, détail, preview) en attendant le
// pull delta (bascule des lectures en local, étape c).

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
