import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/pull_json_support.dart';

// Pull HYDRATANT des inscriptions — `GET /api/v1/sync/enrollments/snapshots`
// (miroir `openApi.yaml`). Variante hydratante du delta : chaque élément est
// l'agrégat COMPLET (inscription entière + snapshot élève canonique + tuteurs),
// auto-suffisant pour reconstituer un dossier de A à Z sur une tablette neuve.
// Même pagination keyset que le delta maigre (ADR-008/009).

/// Page delta keyset des agrégats complets (enveloppe [KeysetPageEnvelope]).
class EnrollmentSnapshotPageDto
    implements KeysetPageDto<EnrollmentAggregateSnapshotDto> {
  @override
  final List<EnrollmentAggregateSnapshotDto> items;
  @override
  final KeysetPageEnvelope page;

  const EnrollmentSnapshotPageDto({required this.items, required this.page});

  factory EnrollmentSnapshotPageDto.fromJson(Map<String, dynamic> j) =>
      EnrollmentSnapshotPageDto(
        items: pullList(j['items'], EnrollmentAggregateSnapshotDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

/// Agrégat descendant complet (miroir du push) : bloc inscription + élève
/// canonique + tuteurs. `serverUpdatedAt` = temps de visibilité serveur (commit)
/// de la ligne — base du curseur de pull (ADR-008).
class EnrollmentAggregateSnapshotDto {
  final EnrollmentSnapshotDto enrollment;
  final StudentSnapshotDto student;
  final List<ParentSnapshotDto> parents;

  /// Réductions octroyées (ADR-021 V1). **À la racine de l'agrégat**, à côté de
  /// [enrollment] et non dedans : l'octroi vit dans sa propre table côté
  /// serveur, et il descend ici plutôt que par un flux propre parce qu'il
  /// voyage déjà dans la page de la ligne qu'il qualifie.
  ///
  /// **Nullable, et la nuance compte** : `null` = l'agrégat ne porte pas la
  /// section (portion non communiquée) — on ne touche alors à rien en local ;
  /// `[]` = ce dossier n'a aucune réduction, et c'est un ordre d'effacer. Les
  /// replier l'un sur l'autre ferait perdre au premier pull les octrois que le
  /// guichet vient de déclarer.
  final List<String>? reductionCodes;
  final String serverUpdatedAt; // ISO-8601

  const EnrollmentAggregateSnapshotDto({
    required this.enrollment,
    required this.student,
    required this.parents,
    this.reductionCodes,
    required this.serverUpdatedAt,
  });

  factory EnrollmentAggregateSnapshotDto.fromJson(Map<String, dynamic> j) =>
      EnrollmentAggregateSnapshotDto(
        enrollment: EnrollmentSnapshotDto.fromJson(
          j['enrollment'] as Map<String, dynamic>,
        ),
        student: StudentSnapshotDto.fromJson(
          j['student'] as Map<String, dynamic>,
        ),
        parents: pullList(j['parents'], ParentSnapshotDto.fromJson),
        // Volontairement hors de `pullList` : `null` et `[]` ne disent pas la
        // même chose, et la distinction est ce qui protège les octrois.
        reductionCodes: j['reductionCodes'] == null
            ? null
            : [
                for (final code in (j['reductionCodes'] as List<dynamic>))
                  if (code is String) code,
              ],
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );
}

/// Bloc inscription complet (toutes colonnes) + valeurs canoniques serveur
/// (`status`, `enrollmentCode`). `updatedAt` = heure métier (LWW) ; l'identité
/// dénormalisée (`firstName`… `gender`) est portée aussi par le [StudentSnapshotDto].
class EnrollmentSnapshotDto {
  final String id;
  final String studentId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String academicYearId;
  final String status;
  final String enrollmentType;
  final String enrollmentCode;
  final String enrollmentDate; // yyyy-MM-dd
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth; // yyyy-MM-dd
  final String gender;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final String? transferReason;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;

  /// « Ancien élève de cette école ». Le contrat le donne non nul (colonne
  /// serveur NOT NULL), la lecture reste tolérante : un snapshot servi par un
  /// back antérieur au champ ne doit pas faire tomber le pull entier.
  final bool formerStudent;

  /// Fiche santé déclarée à l'inscription.
  final String? medicalNotes;
  final String? cancellationReason;

  final String? updatedAt; // ISO-8601 (LWW), optionnel au contrat

  const EnrollmentSnapshotDto({
    required this.id,
    required this.studentId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.academicYearId,
    required this.status,
    required this.enrollmentType,
    required this.enrollmentCode,
    required this.enrollmentDate,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.transferReason,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.formerStudent = false,
    this.medicalNotes,
    this.cancellationReason,
    this.updatedAt,
  });

  factory EnrollmentSnapshotDto.fromJson(Map<String, dynamic> j) =>
      EnrollmentSnapshotDto(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        schoolLevelId: j['schoolLevelId'] as String?,
        schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
        academicYearId: j['academicYearId'] as String,
        status: j['status'] as String,
        enrollmentType: j['enrollmentType'] as String,
        enrollmentCode: j['enrollmentCode'] as String,
        enrollmentDate: j['enrollmentDate'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        surname: (j['surname'] as String?) ?? '',
        dateOfBirth: j['dateOfBirth'] as String,
        gender: j['gender'] as String,
        previousSchoolName: j['previousSchoolName'] as String?,
        previousAcademicYear: j['previousAcademicYear'] as String?,
        previousSchoolLevelGroup: j['previousSchoolLevelGroup'] as String?,
        previousSchoolLevel: j['previousSchoolLevel'] as String?,
        transferReason: j['transferReason'] as String?,
        previousRate: (j['previousRate'] as num?)?.toDouble(),
        previousRank: (j['previousRank'] as num?)?.toInt(),
        validatedPreviousYear: j['validatedPreviousYear'] as bool?,
        // Tolérance délibérée sur un champ que le contrat donne non nul : un
        // back antérieur au champ ne doit pas faire tomber le pull. Le repli
        // est le même que côté serveur — le type d'inscription est la seule
        // information dont on dispose alors.
        formerStudent:
            (j['formerStudent'] as bool?) ??
            (j['enrollmentType'] as String?) == 'RE_ENROLLMENT',
        medicalNotes: j['medicalNotes'] as String?,
        cancellationReason: j['cancellationReason'] as String?,
        // Hors du repli sur la liste vide, comme les sections du bundle : ici
        // aussi c'est la distinction qui décide d'écrire ou de se taire.
        updatedAt: j['updatedAt'] as String?,
      );
}

/// Snapshot élève canonique — porte le matricule attribué serveur, que
/// `StudentInput` (push) ne fournit pas. Ne porte PAS d'`updatedAt` (l'agrégat
/// en fournit un seul).
///
/// Ni téléphone ni e-mail, bien que le serveur les envoie : ils étaient décodés
/// à chaque page, écrits dans `students`, et jamais relus (ADR-015 F8). Les
/// ignorer au décodage évite de les matérialiser en mémoire à chaque agrégat —
/// la même donnée personnelle sans destinataire, une couche plus haut.
///
/// Les contacts du TUTEUR, eux, restent portés par `ParentSnapshotDto` : ils
/// sont affichés et servent de clé d'unicité au rapprochement RE/PRE.
class StudentSnapshotDto {
  final String id;
  final String? matriculationNumber;
  final String firstName;
  final String lastName;
  final String surname;
  final String gender;
  final String dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;

  const StudentSnapshotDto({
    required this.id,
    this.matriculationNumber,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.schoolLevelId,
    this.schoolLevelGroupId,
  });

  factory StudentSnapshotDto.fromJson(Map<String, dynamic> j) =>
      StudentSnapshotDto(
        id: j['id'] as String,
        matriculationNumber: j['matriculationNumber'] as String?,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        surname: (j['surname'] as String?) ?? '',
        gender: j['gender'] as String,
        dateOfBirth: j['dateOfBirth'] as String,
        birthPlace: j['birthPlace'] as String?,
        nationality: j['nationality'] as String?,
        city: j['city'] as String?,
        district: j['district'] as String?,
        municipality: j['municipality'] as String?,
        neighborhood: j['neighborhood'] as String?,
        address: j['address'] as String?,
        schoolLevelId: j['schoolLevelId'] as String?,
        schoolLevelGroupId: j['schoolLevelGroupId'] as String?,
      );
}

/// Tuteur canonique (id serveur résolu par téléphone). `relationshipType` est
/// porté par le lien `student_parent`, pas par la table `parents`.
class ParentSnapshotDto {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String? identificationNumber;
  final String phoneNumber;
  final String? email;
  final String relationshipType;

  /// Tuteur à appeler en urgence **pour l'élève de cet agrégat**. Comme
  /// [relationshipType], il décrit le couple (élève, tuteur) et non le tuteur :
  /// le serveur le rend nul dans les vues sans élève de référence.
  final bool? emergencyContact;

  const ParentSnapshotDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    this.identificationNumber,
    required this.phoneNumber,
    this.email,
    required this.relationshipType,
    this.emergencyContact,
  });

  factory ParentSnapshotDto.fromJson(Map<String, dynamic> j) =>
      ParentSnapshotDto(
        id: j['id'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        surname: j['surname'] as String?,
        identificationNumber: j['identificationNumber'] as String?,
        phoneNumber: j['phoneNumber'] as String,
        email: j['email'] as String?,
        relationshipType: j['relationshipType'] as String,
        emergencyContact: j['emergencyContact'] as bool?,
      );
}
