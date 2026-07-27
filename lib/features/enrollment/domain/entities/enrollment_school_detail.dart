import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

class EnrollmentSchoolDetail extends Equatable {
  final String id;
  final EnrollmentStatus status;
  final String academicYearId;
  final String enrollmentCode;
  final String previousSchoolName;
  final String previousAcademicYear;
  final String previousSchoolLevelGroup;
  final String previousSchoolLevel;

  /// Id référentiel du niveau N-1 (distinct du texte libre
  /// [previousSchoolLevel]) — vide si inconnu (hors réinscription, ou
  /// dossier créé avant l'introduction de ce champ). Alimente le calcul
  /// auto de la classe cible.
  final String previousSchoolLevelId;
  final double previousRate;
  final int? previousRank;
  final bool validatedPreviousYear;
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String? transferReason;
  final String? cancellationReason;

  const EnrollmentSchoolDetail({
    required this.id,
    required this.status,
    required this.academicYearId,
    required this.enrollmentCode,
    required this.previousSchoolName,
    required this.previousAcademicYear,
    required this.previousSchoolLevelGroup,
    required this.previousSchoolLevel,
    this.previousSchoolLevelId = '',
    required this.previousRate,
    this.previousRank,
    required this.validatedPreviousYear,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    this.transferReason,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [
    id,
    status,
    academicYearId,
    enrollmentCode,
    previousSchoolName,
    previousAcademicYear,
    previousSchoolLevelGroup,
    previousSchoolLevel,
    previousSchoolLevelId,
    previousRate,
    previousRank,
    validatedPreviousYear,
    schoolLevelGroupId,
    schoolLevelId,
    transferReason,
    cancellationReason,
  ];
}
