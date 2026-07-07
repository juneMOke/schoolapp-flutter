import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';

/// Adaptateur présentation → domaine offline : projette le [EnrollmentDetail]
/// (agrégé au fil des étapes online) sur le [ConfirmEnrollmentDraft] attendu par
/// le chemin local-first de confirmation.
///
/// L'origine du parcours ([EnrollmentDetailOrigin]) pilote le triplet
/// `enrollmentType` / `status` / `studentId` conformément au contrat du repo
/// offline (cf. [ConfirmEnrollmentDraft]) :
///  - NEW (première inscription) → `NEW_ENROLLMENT` / `IN_PROGRESS`, `studentId`
///    null (le repo génère l'uuid client + matricule « en cours ») ;
///  - RE  → `RE_ENROLLMENT` / `PRE_REGISTERED`, `studentId` connu ;
///  - PRE → `PRE_ENROLLMENT` / `PRE_REGISTERED`, `studentId` connu.
abstract final class EnrollmentConfirmDraftBuilder {
  static ConfirmEnrollmentDraft fromDetail({
    required EnrollmentDetail detail,
    required EnrollmentDetailOrigin origin,
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

  static String _enrollmentType(EnrollmentDetailOrigin origin) {
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration ||
      EnrollmentDetailOrigin.firstRegistration => 'NEW_ENROLLMENT',
      EnrollmentDetailOrigin.reRegistration => 'RE_ENROLLMENT',
      EnrollmentDetailOrigin.preRegistration => 'PRE_ENROLLMENT',
    };
  }

  static String _status(EnrollmentDetailOrigin origin) {
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration ||
      EnrollmentDetailOrigin.firstRegistration => 'IN_PROGRESS',
      EnrollmentDetailOrigin.reRegistration ||
      EnrollmentDetailOrigin.preRegistration => 'PRE_REGISTERED',
    };
  }

  /// NEW → null (uuid client généré par le repo) ; RE/PRE → id serveur connu.
  static String? _resolveStudentId({
    required EnrollmentDetailOrigin origin,
    required String studentId,
  }) {
    return switch (origin) {
      EnrollmentDetailOrigin.newFirstRegistration ||
      EnrollmentDetailOrigin.firstRegistration => null,
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
