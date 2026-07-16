import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';

/// [PullHandler] du module Inscription — une instance par ressource du contrat
/// (`openapi_enrollment_sync.yaml`), enregistrées en DI sur le
/// `PullCoordinator`. **Self-sufficient** : aucun paramètre à résoudre — les
/// années sont optionnelles côté contrat (défaut serveur = année active /
/// N-1), le curseur vit dans `sync_meta` via le repository. La classe est
/// paramétrée (ressource + délégué) plutôt que dupliquée par ressource.
class EnrollmentPullHandler implements PullHandler {
  @override
  final String resource;

  final Future<Either<Failure, EnrollmentPullOutcome>> Function() _pull;

  const EnrollmentPullHandler._(this.resource, this._pull);

  /// Socle référentiel (années, cycles, niveaux, grille tarifaire).
  EnrollmentPullHandler.referential(EnrollmentPullRepository repository)
    : this._(
        EnrollmentPullRepositoryImpl.referentialResource,
        repository.syncReferential,
      );

  /// Cohorte de réinscription N-1 (`ref_previous_year_students`).
  EnrollmentPullHandler.reenrollmentCohort(EnrollmentPullRepository repository)
    : this._(
        EnrollmentPullRepositoryImpl.cohortResource,
        repository.syncReenrollmentCohort,
      );

  /// Préinscriptions du portail parent (`ref_pre_enrollments`).
  EnrollmentPullHandler.preEnrollments(EnrollmentPullRepository repository)
    : this._(
        EnrollmentPullRepositoryImpl.preEnrollmentsResource,
        repository.syncPreEnrollments,
      );

  /// Pull HYDRATANT (agrégats complets → UPSERT `SYNCED`, tablette neuve).
  EnrollmentPullHandler.enrollmentSnapshots(EnrollmentPullRepository repository)
    : this._(
        EnrollmentPullRepositoryImpl.snapshotsResource,
        repository.syncEnrollmentSnapshots,
      );

  /// Delta descendant MAIGRE des inscriptions (réconciliation multi-tablettes).
  EnrollmentPullHandler.enrollmentDelta(EnrollmentPullRepository repository)
    : this._(
        EnrollmentPullRepositoryImpl.deltaResource,
        repository.syncEnrollmentDelta,
      );

  @override
  Future<PullOutcome> pull() async {
    final result = await _pull();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(upserted: outcome.upserted),
    );
  }
}
