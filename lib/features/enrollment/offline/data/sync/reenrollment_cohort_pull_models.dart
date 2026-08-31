import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';
import 'package:school_app_flutter/core/money/money.dart';

// Pull de la cohorte de réinscription N-1 —
// `GET /api/v1/sync/reenrollment-cohort` (miroir `openApi.yaml`).

/// Page de la cohorte N-1 — ressource **statique** paginée par le `studentId`
/// stable (ADR-009 §6), PAS par un temps de visibilité (donc ni watermark ni
/// 304). [nextCursorId] = `studentId` du dernier item, renvoyé au serveur en
/// `cursorId` ; `null` sur la dernière page. [bootstrapComplete] n'est `true`
/// QUE sur la dernière page : le client ne pose son drapeau « roster complet »
/// qu'ici (sinon un device interrompu croirait détenir tout le roster).
class ReenrollmentCohortPageDto {
  final List<ReenrollmentCandidateDto> items;
  final String? nextCursorId;
  final bool bootstrapComplete;
  final int? totalCount;
  final String serverTime;

  const ReenrollmentCohortPageDto({
    required this.items,
    this.nextCursorId,
    required this.bootstrapComplete,
    this.totalCount,
    required this.serverTime,
  });

  factory ReenrollmentCohortPageDto.fromJson(Map<String, dynamic> j) =>
      ReenrollmentCohortPageDto(
        items: pullList(j['items'], ReenrollmentCandidateDto.fromJson),
        nextCursorId: j['nextCursorId'] as String?,
        bootstrapComplete: (j['bootstrapComplete'] as bool?) ?? false,
        totalCount: (j['totalCount'] as num?)?.toInt(),
        serverTime: j['serverTime'] as String,
      );
}

/// Élève N-1 réinscriptible. `studentId` = id CANONIQUE réutilisé par le nouvel
/// enrollment (RE) → aucun doublon.
class ReenrollmentCandidateDto {
  final String studentId;
  final String matriculationNumber;
  final String firstName;
  final String lastName;
  final String surname;
  final String gender; // MALE|FEMALE
  final String dateOfBirth; // yyyy-MM-dd
  final String birthPlace;
  final String? previousAcademicYearId;
  final String? previousSchoolLevelId;
  final String? previousClassroomId;
  final String? guardianName;
  final String? guardianPhone;

  /// Arriérés N-1, **une entrée par devise**.
  ///
  /// C'était un scalaire étiqueté de la devise du premier poste : un élève
  /// devant 425,00 $ et 90 000 FC se voyait annoncer « 90 425,00 $ ». Vide
  /// quand l'élève ne devait rien — et non « zéro » dans une unité qu'il
  /// faudrait choisir.
  final List<Money> previousBalances;

  /// Fiche santé du dossier N-1, descendue pour que le guichet n'ait pas à la
  /// ressaisir. **C'est une proposition, pas la valeur du nouveau dossier** :
  /// le serveur écrit ce que l'agrégat lui envoie, donc un poste qui la lit
  /// sans la repousser perd les allergies de l'enfant au changement d'année.
  final String? medicalNotes;

  const ReenrollmentCandidateDto({
    required this.studentId,
    required this.matriculationNumber,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gender,
    required this.dateOfBirth,
    required this.birthPlace,
    this.previousAcademicYearId,
    this.previousSchoolLevelId,
    this.previousClassroomId,
    this.guardianName,
    this.guardianPhone,
    this.previousBalances = const [],
    this.medicalNotes,
  });

  factory ReenrollmentCandidateDto.fromJson(Map<String, dynamic> j) =>
      ReenrollmentCandidateDto(
        studentId: j['studentId'] as String,
        matriculationNumber: j['matriculationNumber'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        surname: (j['surname'] as String?) ?? '',
        gender: j['gender'] as String,
        dateOfBirth: j['dateOfBirth'] as String,
        birthPlace: (j['birthPlace'] as String?) ?? '',
        previousAcademicYearId: j['previousAcademicYearId'] as String?,
        previousSchoolLevelId: j['previousSchoolLevelId'] as String?,
        previousClassroomId: j['previousClassroomId'] as String?,
        guardianName: j['guardianName'] as String?,
        guardianPhone: j['guardianPhone'] as String?,
        // Absent ou vide = ne doit rien. Jamais un `[Money(0, 'USD')]` de
        // repli : personne n'a choisi cette unité.
        previousBalances: [
          for (final raw
              in (j['previousBalances'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic>)
              Money.parse(
                (raw['amountInCents'] as num?)?.toInt() ?? 0,
                (raw['currency'] as String?) ?? '',
              ),
        ],
        medicalNotes: j['medicalNotes'] as String?,
      );
}
