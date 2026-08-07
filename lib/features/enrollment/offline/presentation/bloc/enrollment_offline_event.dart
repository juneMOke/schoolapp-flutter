import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

abstract class EnrollmentOfflineEvent extends Equatable {
  const EnrollmentOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Charge le détail local d'un dossier.
class LoadLocalEnrollmentDetail extends EnrollmentOfflineEvent {
  final String enrollmentId;

  const LoadLocalEnrollmentDetail(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

/// Amorce un brouillon **complet** (RE/PRE/édition) depuis un dossier chargé —
/// la photo de départ que les étapes du wizard éditeront colonne-à-colonne.
/// [enrollmentId] conserve un id serveur connu (PRE/édition) ; null → uuid neuf.
class SeedDraftRequested extends EnrollmentOfflineEvent {
  final ConfirmEnrollmentDraft seed;
  final String? enrollmentId;

  const SeedDraftRequested(this.seed, {this.enrollmentId});

  @override
  List<Object?> get props => [seed.hashCode, enrollmentId];
}

/// Amorce un brouillon **RE depuis la cohorte N-1 locale**
/// (`ref_previous_year_students`) par `studentId` canonique. Le bloc lit le
/// candidat local, projette la photo de départ (matricule → `source_ref`) et
/// seede le brouillon. [academicYearId] = année cible (bootstrap courant), la
/// cohorte ne portant que l'année N-1. Cohorte non peuplée → erreur (régression
/// assumée tant que le pull dort).
class SeedFromCohortRequested extends EnrollmentOfflineEvent {
  final String studentId;
  final String academicYearId;

  const SeedFromCohortRequested({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}

/// Amorce un brouillon **PRE depuis le snapshot local** (`ref_pre_enrollments`)
/// par `preEnrollmentId` (conservé comme id d'inscription et `source_ref`).
/// [academicYearId] = année cible (bootstrap courant). Snapshot non peuplé →
/// erreur (régression assumée tant que le pull dort).
class SeedFromPreEnrollmentRequested extends EnrollmentOfflineEvent {
  final String preEnrollmentId;
  final String academicYearId;

  const SeedFromPreEnrollmentRequested({
    required this.preEnrollmentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [preEnrollmentId, academicYearId];
}

/// Tire les ressources pull du module (référentiel, cohorte, préinscriptions,
/// delta) — dispatché au montage du module. Silencieux : aucun état émis, le
/// cache local est rafraîchi en fond (best-effort).
class EnrollmentPullRequested extends EnrollmentOfflineEvent {
  const EnrollmentPullRequested();
}
