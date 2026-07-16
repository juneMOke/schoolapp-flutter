part of 'enrollment_local_list_bloc.dart';

sealed class EnrollmentLocalListEvent extends Equatable {
  const EnrollmentLocalListEvent();

  @override
  List<Object?> get props => [];
}

/// Réinitialise le listing (retour à l'état initial : ni requête, ni résultats).
class LocalListResetRequested extends EnrollmentLocalListEvent {
  const LocalListResetRequested();
}

/// Rejoue la dernière requête à sa page courante (re-lecture locale).
class LocalListRefreshRequested extends EnrollmentLocalListEvent {
  const LocalListRefreshRequested();
}

/// Change de page (pagination client-side sur le cache de la dernière requête).
class LocalListPageRequested extends EnrollmentLocalListEvent {
  final int page;

  const LocalListPageRequested({required this.page});

  @override
  List<Object?> get props => [page];
}

/// Liste par statut métier (listing principal — première inscription /
/// préinscriptions).
class LocalListByStatusRequested extends EnrollmentLocalListEvent {
  final String status;
  final String academicYearId;
  final String? enrollmentType;
  final int page;
  final int size;

  const LocalListByStatusRequested({
    required this.status,
    this.academicYearId = '',
    this.enrollmentType,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    enrollmentType,
    page,
    size,
  ];
}

/// Recherche par nom (raffinée client-side sur la base filtrée par statut).
class LocalListByStudentNameRequested extends EnrollmentLocalListEvent {
  final String status;
  final String academicYearId;
  final String? enrollmentType;
  final String firstName;
  final String lastName;
  final String surname;
  final int page;
  final int size;

  const LocalListByStudentNameRequested({
    required this.status,
    this.academicYearId = '',
    this.enrollmentType,
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
    enrollmentType,
    firstName,
    lastName,
    surname,
    page,
    size,
  ];
}

/// Recherche par noms + date de naissance (raffinée client-side).
class LocalListByStudentNamesAndDateOfBirthRequested
    extends EnrollmentLocalListEvent {
  final String status;
  final String academicYearId;
  final String? enrollmentType;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final int page;
  final int size;

  const LocalListByStudentNamesAndDateOfBirthRequested({
    required this.status,
    this.academicYearId = '',
    this.enrollmentType,
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
    enrollmentType,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    page,
    size,
  ];
}

/// Recherche par date de naissance exacte (raffinée client-side).
class LocalListByDateOfBirthRequested extends EnrollmentLocalListEvent {
  final String status;
  final String academicYearId;
  final String? enrollmentType;
  final String dateOfBirth;
  final int page;
  final int size;

  const LocalListByDateOfBirthRequested({
    required this.status,
    this.academicYearId = '',
    this.enrollmentType,
    required this.dateOfBirth,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [
    status,
    academicYearId,
    enrollmentType,
    dateOfBirth,
    page,
    size,
  ];
}

/// Recherche par info académique (réinscriptions) : base = niveaux locaux,
/// raffinement nom client-side.
class LocalListByAcademicInfoRequested extends EnrollmentLocalListEvent {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final int page;
  final int size;

  const LocalListByAcademicInfoRequested({
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
