import 'package:equatable/equatable.dart';

/// Nature d'une requête de liste de résumés d'inscription.
enum EnrollmentSummaryQueryType {
  byStatus,
  byStudentName,
  byStudentNamesAndDateOfBirth,
  byDateOfBirth,
  byAcademicInfo,
}

/// Source d'une recherche [EnrollmentSummaryQueryType.byAcademicInfo] côté
/// listing LOCAL. Discriminateur **interne au bloc local** : il ne change ni le
/// type de requête (les widgets continuent de tester `byAcademicInfo`) ni le
/// bloc online (qui l'ignore).
///
/// - [reenrollmentCohort] (défaut) : vivier N-1 (cohorte) ∪ dossiers locaux de
///   l'année courante — la recherche de **réinscription**.
/// - [currentYearEnrolled] : uniquement les élèves **réellement inscrits** cette
///   année (dossiers finalisés, `sync_status` SYNCED, PENDING_SYNC ou
///   SYNC_ERROR) — la recherche de la **Facturation** (élèves facturables).
/// - [currentYearByStatus] : dossiers de l'année courante bornés au niveau visé
///   ET au statut métier (`status`), brouillons inclus — la recherche « par
///   niveau visé » de la **Première inscription**.
enum AcademicInfoSource {
  reenrollmentCohort,
  currentYearEnrolled,
  currentYearByStatus,
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

  /// Source d'une recherche `byAcademicInfo` (listing local) — voir
  /// [AcademicInfoSource]. Ignoré par les autres types de requête et par le
  /// bloc online.
  final AcademicInfoSource academicInfoSource;

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
    this.academicInfoSource = AcademicInfoSource.reenrollmentCohort,
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
    academicInfoSource: academicInfoSource,
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
    academicInfoSource,
  ];
}
