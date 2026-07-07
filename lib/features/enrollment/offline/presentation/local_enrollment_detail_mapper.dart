import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

/// Adaptateur domaine offline → agrégat online : projette le brouillon local
/// ([LocalEnrollmentDetail]) sur le [EnrollmentDetail] consommé par le wizard.
///
/// Les identifiants de niveau visé (`schoolLevelId` / `schoolLevelGroupId`)
/// stockés en local sont résolus en objets [SchoolLevel] / [SchoolLevelGroup]
/// via les listes fournies (dérivées du bootstrap). Faute de correspondance, un
/// objet minimal portant l'id brut est renvoyé (jamais null, pour préserver
/// l'hydratation des étapes). Les champs serveur absents hors-ligne (matricule)
/// restent vides — un placeholder « en cours » est géré côté UI.
EnrollmentDetail mapLocalToEnrollmentDetail(
  LocalEnrollmentDetail local, {
  required List<SchoolLevel> levels,
  required List<SchoolLevelGroup> groups,
}) {
  final enrollment = local.enrollment;
  final student = local.student;

  final schoolLevel = _resolveLevel(enrollment.schoolLevelId, levels);
  final schoolLevelGroup = _resolveGroup(enrollment.schoolLevelGroupId, groups);

  return EnrollmentDetail(
    studentDetail: StudentDetail(
      id: student.id,
      firstName: student.firstName,
      lastName: student.lastName,
      surname: student.surname ?? '',
      dateOfBirth: student.dateOfBirth,
      gender: _mapGender(student.gender),
      birthPlace: student.birthPlace ?? '',
      nationality: student.nationality ?? '',
      photoUrl: null,
      city: student.city ?? '',
      district: student.district ?? '',
      municipality: student.municipality ?? '',
      neighborhood: student.neighborhood ?? '',
      address: student.address ?? '',
      schoolLevel: schoolLevel,
      schoolLevelGroup: schoolLevelGroup,
    ),
    parentDetails: local.parents
        .map(
          (parent) => ParentSummary(
            id: parent.id,
            firstName: parent.firstName,
            lastName: parent.lastName,
            surname: parent.surname,
            identificationNumber: parent.identificationNumber ?? '',
            phoneNumber: parent.phoneNumber,
            email: parent.email ?? '',
            relationshipType: RelationshipType.fromString(
              parent.relationshipType.apiValue,
            ),
          ),
        )
        .toList(growable: false),
    enrollmentDetail: EnrollmentSchoolDetail(
      id: enrollment.id,
      status: EnrollmentStatus.fromString(enrollment.status.apiValue),
      academicYearId: enrollment.academicYearId,
      enrollmentCode: enrollment.enrollmentCode ?? '',
      previousSchoolName: enrollment.previousSchoolName ?? '',
      previousAcademicYear: enrollment.previousAcademicYear ?? '',
      previousSchoolLevelGroup: enrollment.previousSchoolLevelGroup ?? '',
      previousSchoolLevel: enrollment.previousSchoolLevel ?? '',
      previousRate: enrollment.previousRate ?? 0,
      previousRank: enrollment.previousRank,
      validatedPreviousYear: enrollment.validatedPreviousYear ?? false,
      schoolLevelGroupId: enrollment.schoolLevelGroupId ?? '',
      schoolLevelId: enrollment.schoolLevelId ?? '',
      transferReason: enrollment.transferReason,
      cancellationReason: enrollment.cancellationReason,
    ),
  );
}

/// Agrégat vide « amorce » d'un brouillon NEW avant l'étape 0 : porte seulement
/// les ids client figés + l'année scolaire courante (pré-requis de l'étape
/// Identité). Toutes les autres valeurs sont vides, comme [EnrollmentDetail.empty].
EnrollmentDetail buildDraftSeedDetail({
  required String enrollmentId,
  required String studentId,
  required String academicYearId,
}) {
  return EnrollmentDetail(
    studentDetail: StudentDetail(
      id: studentId,
      firstName: '',
      lastName: '',
      surname: '',
      dateOfBirth: '',
      gender: Gender.male,
      birthPlace: '',
      nationality: '',
      photoUrl: null,
      city: '',
      district: '',
      municipality: '',
      neighborhood: '',
      address: '',
      schoolLevel: const SchoolLevel(
        id: '',
        name: '',
        code: '',
        displayOrder: 0,
        splitIntoClassrooms: false,
      ),
      schoolLevelGroup: const SchoolLevelGroup(id: '', name: '', code: ''),
    ),
    parentDetails: const [],
    enrollmentDetail: EnrollmentSchoolDetail(
      id: enrollmentId,
      status: EnrollmentStatus.inProgress,
      academicYearId: academicYearId,
      enrollmentCode: '',
      previousSchoolName: '',
      previousAcademicYear: '',
      previousSchoolLevelGroup: '',
      previousSchoolLevel: '',
      previousRate: 0,
      previousRank: null,
      validatedPreviousYear: false,
      schoolLevelGroupId: '',
      schoolLevelId: '',
    ),
  );
}

/// Aplati les niveaux scolaires du bootstrap en entités domaine (résolution du
/// niveau visé par le mapper).
List<SchoolLevel> schoolLevelsFromBootstrap(Bootstrap? bootstrap) {
  if (bootstrap == null) return const [];
  return [
    for (final group in bootstrap.schoolLevelGroups)
      for (final bundle in group.schoolLevels)
        SchoolLevel(
          id: bundle.schoolLevel.id,
          name: bundle.schoolLevel.name,
          code: bundle.schoolLevel.code,
          displayOrder: bundle.schoolLevel.displayOrder,
          splitIntoClassrooms: bundle.schoolLevel.splitIntoClassrooms,
        ),
  ];
}

/// Aplati les groupes de niveaux (cycles) du bootstrap en entités domaine.
List<SchoolLevelGroup> schoolLevelGroupsFromBootstrap(Bootstrap? bootstrap) {
  if (bootstrap == null) return const [];
  return bootstrap.schoolLevelGroups
      .map(
        (group) => SchoolLevelGroup(
          id: group.schoolLevelGroup.id,
          name: group.schoolLevelGroup.name,
          code: group.schoolLevelGroup.code,
        ),
      )
      .toList(growable: false);
}

Gender _mapGender(OfflineGender gender) =>
    gender == OfflineGender.female ? Gender.female : Gender.male;

SchoolLevel _resolveLevel(String? id, List<SchoolLevel> levels) {
  final normalized = id?.trim() ?? '';
  for (final level in levels) {
    if (level.id == normalized && normalized.isNotEmpty) {
      return level;
    }
  }
  return SchoolLevel(
    id: normalized,
    name: '',
    code: '',
    displayOrder: 0,
    splitIntoClassrooms: false,
  );
}

SchoolLevelGroup _resolveGroup(String? id, List<SchoolLevelGroup> groups) {
  final normalized = id?.trim() ?? '';
  for (final group in groups) {
    if (group.id == normalized && normalized.isNotEmpty) {
      return group;
    }
  }
  return SchoolLevelGroup(id: normalized, name: '', code: '');
}
