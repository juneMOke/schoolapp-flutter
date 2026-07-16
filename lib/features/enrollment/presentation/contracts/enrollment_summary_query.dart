import 'package:equatable/equatable.dart';

/// Nature d'une requête de liste de résumés d'inscription.
enum EnrollmentSummaryQueryType {
  byStatus,
  byStudentName,
  byStudentNamesAndDateOfBirth,
  byDateOfBirth,
  byAcademicInfo,
}

/// Photo immuable de la dernière requête de liste jouée — sert à la rejouer
/// (refresh / pagination) et à reconstituer les chips de critères. Partagée par
/// le bloc online (`EnrollmentBloc`) et le bloc de listing LOCAL
/// (`EnrollmentLocalListBloc`).
class EnrollmentSummariesQuery extends Equatable {
  final EnrollmentSummaryQueryType type;
  final String status;
  final String academicYearId;
  final int page;
  final int size;
  final String? firstName;
  final String? lastName;
  final String? surname;
  final String? dateOfBirth;
  final String? schoolLevelGroupId;
  final String? schoolLevelId;

  /// Filtre de **type d'inscription** (valeur API, ex. `PRE_ENROLLMENT`). Axe
  /// distinct de [status] : la page Pré-inscriptions le fixe pour exclure les
  /// dossiers de réinscription (même statut PRE_REGISTERED). Null = pas de
  /// filtre par type (Première inscription, Réinscriptions).
  final String? enrollmentType;

  const EnrollmentSummariesQuery({
    required this.type,
    required this.status,
    required this.academicYearId,
    required this.page,
    required this.size,
    this.firstName,
    this.lastName,
    this.surname,
    this.dateOfBirth,
    this.schoolLevelGroupId,
    this.schoolLevelId,
    this.enrollmentType,
  });

  /// Réplique la requête en changeant uniquement la page — utilisé par la
  /// pagination client-side du listing local pour garder la photo cohérente
  /// (le refresh rejoue la requête à sa page courante).
  EnrollmentSummariesQuery copyWithPage(int page) => EnrollmentSummariesQuery(
    type: type,
    status: status,
    academicYearId: academicYearId,
    page: page,
    size: size,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
    enrollmentType: enrollmentType,
  );

  @override
  List<Object?> get props => [
    type,
    status,
    academicYearId,
    page,
    size,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    schoolLevelGroupId,
    schoolLevelId,
    enrollmentType,
  ];
}
