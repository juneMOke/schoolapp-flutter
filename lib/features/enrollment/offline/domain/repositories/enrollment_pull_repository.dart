import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Pulls du module Inscription (miroir `openApi.yaml`, section Sync) :
/// peuplent le cache local, jamais l'affichage direct (ADR-003). Chaque méthode
/// est self-sufficient (curseur via `sync_meta`) et idempotente — appelée par
/// les `EnrollmentPullHandler` du `PullCoordinator`.
abstract class EnrollmentPullRepository {
  /// Socle référentiel (années, cycles, niveaux, grille tarifaire) — bundle full
  /// always-200, gelé sur la saison (D2).
  Future<Either<Failure, EnrollmentPullOutcome>> syncReferential();

  /// Cohorte de réinscription N-1 (`ref_previous_year_students`) — ressource
  /// STATIQUE paginée par `cursorId`, parcourue jusqu'à `bootstrapComplete` puis
  /// remplacée d'un bloc (D3). Un roster interrompu est jeté (jamais partiel).
  /// **Gelée sur la saison** : une fois le roster complet en cache, les appels
  /// suivants court-circuitent sans réseau (`notModified`) — rejoué seulement
  /// tant qu'aucun pull complet n'a réussi.
  Future<Either<Failure, EnrollmentPullOutcome>> syncReenrollmentCohort();

  /// Préinscriptions du portail parent (`ref_pre_enrollments`) — delta keyset
  /// `cursor` (D4).
  Future<Either<Failure, EnrollmentPullOutcome>> syncPreEnrollments();

  /// Delta descendant MAIGRE des inscriptions (réconciliation multi-tablettes,
  /// UPDATE-only des lignes déjà SYNCED) — delta keyset `cursor` (ADR-008/009).
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentDelta();

  /// Pull HYDRATANT (agrégats complets = inscription + élève canonique +
  /// tuteurs) : UPSERT `enrollments`+`students`+`parents` en `SYNCED` pour
  /// reconstituer une tablette neuve — delta keyset `cursor`.
  Future<Either<Failure, EnrollmentPullOutcome>> syncEnrollmentSnapshots();
}
