import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

/// Adaptateur présentation → domaine offline : projette le [EnrollmentDetail]
/// chargé du serveur sur le [ConfirmEnrollmentDraft] — aujourd'hui la **photo
/// de départ (seed)** du brouillon local RE/PRE/reprise, éditée ensuite par
/// étape puis flushée en un agrégat unique.
///
/// L'origine du parcours ([EnrollmentDetailOrigin]) pilote le triplet
/// `enrollmentType` / `status` / `studentId` conformément au contrat du repo
/// offline (cf. [ConfirmEnrollmentDraft]) :
///  - NEW (première inscription) → `NEW_ENROLLMENT` / `IN_PROGRESS`, `studentId`
///    null (le repo génère l'uuid client + matricule « en cours ») ;
///  - RE  → `RE_ENROLLMENT` / `PRE_REGISTERED`, `studentId` connu ;
///  - PRE → `PRE_ENROLLMENT` / `PRE_REGISTERED`, `studentId` connu.
/// [sourceRef] = référence d'origine du contrat agrégat (id de préinscription
/// PRE ; matricule RE fourni plus tard par le seed cohorte locale).
abstract final class EnrollmentConfirmDraftBuilder {
  static ConfirmEnrollmentDraft fromDetail({
    required EnrollmentDetail detail,
    required EnrollmentDetailOrigin origin,
    String? sourceRef,
  }) {
    final student = detail.studentDetail;
    final enrollment = detail.enrollmentDetail;

    final enrollmentType = _enrollmentType(origin);
    final status = _status(origin);
    final studentId = _resolveStudentId(origin: origin, studentId: student.id);

    final schoolLevelId =
        _nullIfEmpty(enrollment.schoolLevelId) ??
        _nullIfEmpty(student.schoolLevel.id);
    final schoolLevelGroupId =
        _nullIfEmpty(enrollment.schoolLevelGroupId) ??
        _nullIfEmpty(student.schoolLevelGroup.id);

    return ConfirmEnrollmentDraft(
      studentId: studentId,
      firstName: student.firstName,
      lastName: student.lastName,
      surname: _nullIfEmpty(student.surname),
      gender: student.gender == Gender.female ? 'FEMALE' : 'MALE',
      dateOfBirth: student.dateOfBirth,
      birthPlace: _nullIfEmpty(student.birthPlace),
      nationality: _nullIfEmpty(student.nationality),
      city: _nullIfEmpty(student.city),
      district: _nullIfEmpty(student.district),
      municipality: _nullIfEmpty(student.municipality),
      neighborhood: _nullIfEmpty(student.neighborhood),
      address: _nullIfEmpty(student.address),
      enrollmentType: enrollmentType,
      status: status,
      sourceRef: sourceRef,
      academicYearId: enrollment.academicYearId,
      schoolLevelId: schoolLevelId,
      schoolLevelGroupId: schoolLevelGroupId,
      enrollmentDate: _today(),
      previousSchoolName: _nullIfEmpty(enrollment.previousSchoolName),
      previousAcademicYear: _nullIfEmpty(enrollment.previousAcademicYear),
      previousSchoolLevelGroup: _nullIfEmpty(
        enrollment.previousSchoolLevelGroup,
      ),
      previousSchoolLevel: _nullIfEmpty(enrollment.previousSchoolLevel),
      previousSchoolLevelId: _nullIfEmpty(enrollment.previousSchoolLevelId),
      previousRate: enrollment.previousRate,
      previousRank: enrollment.previousRank,
      validatedPreviousYear: enrollment.validatedPreviousYear,
      transferReason: _nullIfEmpty(enrollment.transferReason ?? ''),
      parents: detail.parentDetails
          .map(
            (parent) => ConfirmParentDraft(
              firstName: parent.firstName,
              lastName: parent.lastName,
              surname: _nullIfEmpty(parent.surname ?? ''),
              phoneNumber: parent.phoneNumber,
              email: _nullIfEmpty(parent.email),
              // L'enum est déjà aligné sur les valeurs API SCREAMING_SNAKE.
              relationshipType: parent.relationshipType.name.toUpperCase(),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Seed **RE depuis la cohorte N-1 locale** (`ref_previous_year_students`).
  /// L'élève canonique est conservé (`studentId`), le matricule sert de
  /// `source_ref` ET de matricule du brouillon ; l'année cible vient du
  /// bootstrap courant (la cohorte ne porte que l'année N-1). Le tuteur
  /// dénormalisé (nom + téléphone) est projeté en un `ConfirmParentDraft` que
  /// l'utilisateur complète à l'étape Tuteurs. Antécédents (établissement,
  /// cycle, niveau N-1) préremplis depuis les libellés résolus localement par
  /// [ReenrollmentCandidate] (cf. `EnrollmentSeedDao._candidateSelect`) — la
  /// moyenne/rang/année validée restent, eux, à saisir (absents du contrat
  /// backend de la cohorte).
  static ConfirmEnrollmentDraft fromReenrollmentCandidate({
    required ReenrollmentCandidate candidate,
    required String academicYearId,
  }) {
    return ConfirmEnrollmentDraft(
      studentId: _nullIfEmpty(candidate.studentId),
      firstName: candidate.firstName,
      lastName: candidate.lastName,
      surname: _nn(candidate.surname),
      gender: _normalizeGender(candidate.gender),
      dateOfBirth: candidate.dateOfBirth,
      birthPlace: _nn(candidate.birthPlace),
      matriculationNumber: _nullIfEmpty(candidate.matriculationNumber),
      enrollmentType: 'RE_ENROLLMENT',
      status: 'PRE_REGISTERED',
      sourceRef: _nullIfEmpty(candidate.matriculationNumber),
      academicYearId: academicYearId,
      previousSchoolLevelId: _nn(candidate.previousSchoolLevelId),
      previousSchoolLevelGroup: _nn(candidate.previousSchoolLevelGroupName),
      previousSchoolLevel: _nn(candidate.previousSchoolLevelName),
      previousSchoolName: _nn(candidate.previousSchoolName),
      enrollmentDate: _today(),
      parents: _guardianParents(
        candidate.guardianName,
        candidate.guardianPhone,
      ),
    );
  }

  /// Seed **PRE depuis le snapshot local** (`ref_pre_enrollments`). L'`id` de
  /// préinscription est conservé comme enrollmentId (au seed, hors builder) et
  /// comme `source_ref` ; l'élève n'existe pas encore → `studentId` null (uuid
  /// client généré au seed). Niveau souhaité repris ; année du bootstrap courant.
  static ConfirmEnrollmentDraft fromPreEnrollment({
    required PreEnrollmentCandidate pre,
    required String academicYearId,
  }) {
    return ConfirmEnrollmentDraft(
      studentId: null,
      firstName: pre.firstName,
      lastName: pre.lastName,
      surname: _nn(pre.surname),
      gender: _normalizeGender(pre.gender),
      dateOfBirth: pre.dateOfBirth ?? '',
      birthPlace: _nn(pre.birthPlace),
      enrollmentType: 'PRE_ENROLLMENT',
      status: 'PRE_REGISTERED',
      sourceRef: _nullIfEmpty(pre.id),
      academicYearId: academicYearId,
      schoolLevelId: _nn(pre.desiredSchoolLevelId),
      enrollmentDate: _today(),
      parents: _guardianParents(pre.guardianName, pre.guardianPhone),
    );
  }

  /// Tuteur dénormalisé (nom complet + téléphone) → 0 ou 1 `ConfirmParentDraft`.
  /// Sans téléphone (clé de déduplication G3), aucun tuteur n'est projeté. Le
  /// nom complet est scindé en prénom (1er mot) / nom (reste), best-effort.
  static List<ConfirmParentDraft> _guardianParents(
    String? name,
    String? phone,
  ) {
    final trimmedPhone = phone?.trim() ?? '';
    if (trimmedPhone.isEmpty) return const [];
    final trimmedName = name?.trim() ?? '';
    final parts = trimmedName.isEmpty
        ? const <String>[]
        : trimmedName.split(RegExp(r'\s+'));
    return [
      ConfirmParentDraft(
        firstName: parts.isNotEmpty ? parts.first : '',
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        phoneNumber: trimmedPhone,
        relationshipType: 'OTHER',
      ),
    ];
  }

  /// Normalise le genre (valeur API cohorte) sur `MALE|FEMALE|OTHER` ; défaut
  /// `MALE` (le modèle domaine `Gender` n'a que 2 valeurs — cf. B1).
  static String _normalizeGender(String? raw) {
    final v = raw?.trim().toUpperCase();
    return (v == 'FEMALE' || v == 'MALE' || v == 'OTHER') ? v! : 'MALE';
  }

  static String? _nn(String? value) =>
      (value == null) ? null : _nullIfEmpty(value);

  static String _enrollmentType(EnrollmentDetailOrigin origin) {
    // localDraftResume ne passe jamais par le seed (l'agrégat est déjà en base) ;
    // groupé avec NEW pour l'exhaustivité.
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration ||
      EnrollmentDetailOrigin.firstRegistration ||
      EnrollmentDetailOrigin.localDraftResume => 'NEW_ENROLLMENT',
      EnrollmentDetailOrigin.reRegistration => 'RE_ENROLLMENT',
      EnrollmentDetailOrigin.preRegistration => 'PRE_ENROLLMENT',
    };
  }

  static String _status(EnrollmentDetailOrigin origin) {
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration ||
      EnrollmentDetailOrigin.firstRegistration ||
      EnrollmentDetailOrigin.localDraftResume => 'IN_PROGRESS',
      EnrollmentDetailOrigin.reRegistration ||
      EnrollmentDetailOrigin.preRegistration => 'PRE_REGISTERED',
    };
  }

  /// NEW → null (uuid client généré par le repo) ; RE/PRE → id serveur canonique.
  /// **Reprise firstRegistration** (dossier serveur IN_PROGRESS ré-ouvert) →
  /// on CONSERVE le `studentId` : l'élève existe déjà côté serveur, en générer
  /// un neuf créerait un doublon au push.
  static String? _resolveStudentId({
    required EnrollmentDetailOrigin origin,
    required String studentId,
  }) {
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration => null,
      EnrollmentDetailOrigin.firstRegistration ||
      EnrollmentDetailOrigin.localDraftResume ||
      EnrollmentDetailOrigin.reRegistration ||
      EnrollmentDetailOrigin.preRegistration => _nullIfEmpty(studentId),
    };
  }

  static String _today() => DateTime.now().toIso8601String().split('T').first;

  static String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
