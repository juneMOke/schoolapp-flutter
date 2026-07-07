import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

abstract class EnrollmentDraftEvent extends Equatable {
  const EnrollmentDraftEvent();

  @override
  List<Object?> get props => [];
}

/// Démarre un brouillon : fige les ids client (studentId réutilisé en RE/PRE).
class StartDraftRequested extends EnrollmentDraftEvent {
  final String? existingStudentId;

  const StartDraftRequested({this.existingStudentId});

  @override
  List<Object?> get props => [existingStudentId];
}

/// Étape 0 : crée les 2 lignes DRAFT (élève + inscription).
class SaveDraftIdentityRequested extends EnrollmentDraftEvent {
  final String enrollmentId;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String gender;
  final String dateOfBirth;
  final String? birthPlace;
  final String? nationality;
  final String? matriculationNumber;
  final String enrollmentType;
  final String status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate;

  const SaveDraftIdentityRequested({
    required this.enrollmentId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.gender,
    required this.dateOfBirth,
    this.birthPlace,
    this.nationality,
    this.matriculationNumber,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    studentId,
    firstName,
    lastName,
    surname,
    gender,
    dateOfBirth,
    birthPlace,
    nationality,
    matriculationNumber,
    enrollmentType,
    status,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    enrollmentDate,
  ];
}

/// Étape Adresse.
class SaveDraftAddressRequested extends EnrollmentDraftEvent {
  final String studentId;
  final String? city;
  final String? district;
  final String? municipality;
  final String? neighborhood;
  final String? address;
  final String? phoneNumber;

  const SaveDraftAddressRequested({
    required this.studentId,
    this.city,
    this.district,
    this.municipality,
    this.neighborhood,
    this.address,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    studentId,
    city,
    district,
    municipality,
    neighborhood,
    address,
    phoneNumber,
  ];
}

/// Étape Antécédents scolaires.
class SaveDraftPreviousAcademicRequested extends EnrollmentDraftEvent {
  final String enrollmentId;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;

  const SaveDraftPreviousAcademicRequested({
    required this.enrollmentId,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.transferReason,
  });

  @override
  List<Object?> get props => [
    enrollmentId,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousRate,
    previousRank,
    validatedPreviousYear,
    transferReason,
  ];
}

/// Étape Affectation (niveau visé).
class SaveDraftTargetAcademicRequested extends EnrollmentDraftEvent {
  final String enrollmentId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;

  const SaveDraftTargetAcademicRequested({
    required this.enrollmentId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [enrollmentId, schoolLevelId, schoolLevelGroupId];
}

/// Étape Tuteurs.
class SaveDraftGuardiansRequested extends EnrollmentDraftEvent {
  final String studentId;
  final List<ConfirmParentDraft> parents;

  const SaveDraftGuardiansRequested({
    required this.studentId,
    required this.parents,
  });

  @override
  List<Object?> get props => [studentId, parents.length];
}

/// Charge le détail du brouillon.
class LoadDraftDetailRequested extends EnrollmentDraftEvent {
  final String enrollmentId;

  const LoadDraftDetailRequested(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

/// Étape Résumé : confirme le brouillon (DRAFT → PENDING_SYNC).
class FinalizeDraftRequested extends EnrollmentDraftEvent {
  final String enrollmentId;
  final bool emitDocument;

  const FinalizeDraftRequested(this.enrollmentId, {this.emitDocument = true});

  @override
  List<Object?> get props => [enrollmentId, emitDocument];
}
