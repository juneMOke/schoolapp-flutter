import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Helpers de (dé)sérialisation sqflite (INTEGER 0/1 ↔ bool).
bool? _boolFromDb(Object? v) => v == null ? null : (v as int) != 0;
int? _boolToDb(bool? v) => v == null ? null : (v ? 1 : 0);

/// Modèle de la table `enrollments`.
class EnrollmentLocalModel {
  final String id;
  final String studentId;
  final String enrollmentType;
  final String status;
  final String academicYearId;
  final String? schoolLevelId;
  final String? schoolLevelGroupId;
  final String enrollmentDate;
  final String? enrollmentCode;

  /// Référence d'origine du dossier (contrat agrégat) : matricule (RE),
  /// id de préinscription (PRE), null (NEW).
  final String? sourceRef;
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
  final String syncStatus;
  final String? syncError;
  final int? syncedAt;
  final int updatedAt;

  const EnrollmentLocalModel({
    required this.id,
    required this.studentId,
    required this.enrollmentType,
    required this.status,
    required this.academicYearId,
    this.schoolLevelId,
    this.schoolLevelGroupId,
    required this.enrollmentDate,
    this.enrollmentCode,
    this.sourceRef,
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
    this.syncStatus = 'PENDING_SYNC',
    this.syncError,
    this.syncedAt,
    this.updatedAt = 0,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'student_id': studentId,
    'enrollment_type': enrollmentType,
    'status': status,
    'academic_year_id': academicYearId,
    'school_level_id': schoolLevelId,
    'school_level_group_id': schoolLevelGroupId,
    'enrollment_date': enrollmentDate,
    'enrollment_code': enrollmentCode,
    'source_ref': sourceRef,
    'previous_school_name': previousSchoolName,
    'previous_academic_year': previousAcademicYear,
    'previous_school_level_group': previousSchoolLevelGroup,
    'previous_school_level': previousSchoolLevel,
    'previous_school_level_id': previousSchoolLevelId,
    'previous_rate': previousRate,
    'previous_rank': previousRank,
    'validated_previous_year': _boolToDb(validatedPreviousYear),
    'transfer_reason': transferReason,
    'cancellation_reason': cancellationReason,
    'emit_document': _boolToDb(emitDocument),
    'sync_status': syncStatus,
    'sync_error': syncError,
    'synced_at': syncedAt,
    'updated_at': updatedAt,
  };

  factory EnrollmentLocalModel.fromMap(Map<String, Object?> m) =>
      EnrollmentLocalModel(
        id: m['id'] as String,
        studentId: m['student_id'] as String,
        enrollmentType: m['enrollment_type'] as String,
        status: m['status'] as String,
        academicYearId: m['academic_year_id'] as String,
        schoolLevelId: m['school_level_id'] as String?,
        schoolLevelGroupId: m['school_level_group_id'] as String?,
        enrollmentDate: m['enrollment_date'] as String,
        enrollmentCode: m['enrollment_code'] as String?,
        sourceRef: m['source_ref'] as String?,
        previousSchoolName: m['previous_school_name'] as String?,
        previousAcademicYear: m['previous_academic_year'] as String?,
        previousSchoolLevelGroup: m['previous_school_level_group'] as String?,
        previousSchoolLevel: m['previous_school_level'] as String?,
        previousSchoolLevelId: m['previous_school_level_id'] as String?,
        previousRate: (m['previous_rate'] as num?)?.toDouble(),
        previousRank: m['previous_rank'] as int?,
        validatedPreviousYear: _boolFromDb(m['validated_previous_year']),
        transferReason: m['transfer_reason'] as String?,
        cancellationReason: m['cancellation_reason'] as String?,
        emitDocument: _boolFromDb(m['emit_document']) ?? true,
        syncStatus: (m['sync_status'] as String?) ?? 'PENDING_SYNC',
        syncError: m['sync_error'] as String?,
        syncedAt: m['synced_at'] as int?,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  LocalEnrollment toEntity() => LocalEnrollment(
    id: id,
    studentId: studentId,
    enrollmentType: EnrollmentType.fromApiValue(enrollmentType),
    status: OfflineEnrollmentStatus.fromApiValue(status),
    academicYearId: academicYearId,
    schoolLevelId: schoolLevelId,
    schoolLevelGroupId: schoolLevelGroupId,
    enrollmentDate: enrollmentDate,
    enrollmentCode: enrollmentCode,
    previousSchoolName: previousSchoolName,
    previousAcademicYear: previousAcademicYear,
    previousSchoolLevelGroup: previousSchoolLevelGroup,
    previousSchoolLevel: previousSchoolLevel,
    previousSchoolLevelId: previousSchoolLevelId,
    previousRate: previousRate,
    previousRank: previousRank,
    validatedPreviousYear: validatedPreviousYear,
    transferReason: transferReason,
    cancellationReason: cancellationReason,
    emitDocument: emitDocument,
    syncState: SyncState.fromDbValue(syncStatus),
    syncError: syncError,
  );
}
