import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';

/// Dossier d'inscription lu depuis sqflite.
class LocalEnrollment extends Equatable {
  final String id;
  final String studentId;
  final EnrollmentType enrollmentType;
  final OfflineEnrollmentStatus status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate;
  final String? enrollmentCode;
  final String? previousSchoolName;
  final String? previousAcademicYear;
  final String? previousSchoolLevelGroup;
  final String? previousSchoolLevel;

  /// Id référentiel du niveau N-1 (distinct du texte libre
  /// [previousSchoolLevel]) — seedé pour les réinscriptions, alimente le
  /// calcul auto de la classe cible.
  final String? previousSchoolLevelId;
  final double? previousRate;
  final int? previousRank;
  final bool? validatedPreviousYear;
  final String? transferReason;
  final String? cancellationReason;
  final bool emitDocument;
  final SyncState syncState;
  final String? syncError;

  const LocalEnrollment({
    required this.id,
    required this.studentId,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.enrollmentCode,
    this.previousSchoolName,
    this.previousAcademicYear,
    this.previousSchoolLevelGroup,
    this.previousSchoolLevel,
    this.previousSchoolLevelId,
    this.previousRate,
    this.previousRank,
    this.validatedPreviousYear,
    this.transferReason,
    this.cancellationReason,
    this.emitDocument = true,
    this.syncState = SyncState.pendingSync,
    this.syncError,
  });

  @override
  List<Object?> get props => [
    id,
    studentId,
    enrollmentType,
    status,
    academicYearId,
    schoolLevelId,
    schoolLevelGroupId,
    enrollmentDate,
    enrollmentCode,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousSchoolLevelId,
    previousRate,
    previousRank,
    validatedPreviousYear,
    transferReason,
    cancellationReason,
    emitDocument,
    syncState,
    syncError,
  ];
}
