import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Draft d'un tuteur saisi (le repo générera l'uuid provisoire).
class ConfirmParentDraft {
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String? email;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  const ConfirmParentDraft({
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    this.email,
    this.relationshipType = 'OTHER',
  });
}

/// Draft d'une confirmation d'inscription (entrée du chemin local-first).
///
/// `studentId` non-null = RE/PRE (élève préexistant serveur, matricule connu) ;
/// null = NEW (le repo génère l'uuid client, matricule « en cours »).
class ConfirmEnrollmentDraft {
  final String? studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender; // MALE|FEMALE|OTHER
  final String dateOfBirth; // yyyy-MM-dd
  final String? birthPlace;
  final String? nationality;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? phoneNumber;
  final String? matriculationNumber; // non-null en RE (cohorte)

  final String enrollmentType; // NEW_ENROLLMENT|RE_ENROLLMENT|PRE_ENROLLMENT
  final String status; // IN_PROGRESS (NEW) | PRE_REGISTERED (RE/PRE)
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate; // yyyy-MM-dd (date terrain)
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;
  final bool emitDocument;

  final List<ConfirmParentDraft> parents;

  const ConfirmEnrollmentDraft({
    this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.phoneNumber,
    this.matriculationNumber,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.transferReason,
    this.emitDocument = true,
    this.parents = const [],
  });
}

/// Repository offline-first du module Inscription : écritures local-first
/// (confirmation) et lectures servies depuis sqflite.
abstract class EnrollmentOfflineRepository {
  /// Confirme un dossier (transaction locale + enqueue outbox). Renvoie l'id
  /// d'inscription (uuid client) immédiatement, sans attente réseau.
  Future<Either<Failure, String>> confirmEnrollment(
    ConfirmEnrollmentDraft draft,
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> getEnrollments({
    String? status,
  });

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByName(
    String query,
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByDateOfBirth(
    String dateOfBirth,
  );

  Future<Either<Failure, List<LocalEnrollmentListItem>>> searchByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  });

  Future<Either<Failure, LocalEnrollmentDetail>> getDetail(String enrollmentId);
}
