import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';

/// Tire les cinq ressources pull du module Inscription (référentiel, cohorte
/// N-1, préinscriptions, snapshots hydratants, delta descendant) — déclenché au
/// montage du module, en plus du cycle global du `PullCoordinator` (retour
/// online). Le montage est le moment d'hydratation d'une tablette neuve.
///
/// Best-effort : chaque ressource est isolée (un échec ne bloque pas les
/// autres) ; le bilan agrège les compteurs pour un éventuel diagnostic. Aucun
/// échec n'est propagé — le cache local reste simplement en l'état.
///
/// L'ordre est PORTEUR : `syncEnrollmentSnapshots` (INSERT hydratant) précède
/// `syncEnrollmentDelta` (UPDATE-only) — mêmes contraintes qu'en DI
/// (`registerEnrollmentFinanceOffline`), à garder synchronisées.
class SyncEnrollmentPullsUseCase {
  final EnrollmentPullRepository _repository;

  const SyncEnrollmentPullsUseCase(this._repository);

  Future<EnrollmentPullsReport> call() async {
    var updated = 0, notModified = 0, failed = 0;
    for (final pull in [
      _repository.syncReferential,
      _repository.syncReenrollmentCohort,
      _repository.syncPreEnrollments,
      _repository.syncEnrollmentSnapshots,
      _repository.syncEnrollmentDelta,
    ]) {
      final result = await pull();
      result.fold((_) => failed++, (EnrollmentPullOutcome outcome) {
        outcome.notModified ? notModified++ : updated++;
      });
    }
    return EnrollmentPullsReport(
      updated: updated,
      notModified: notModified,
      failed: failed,
    );
  }
}

/// Bilan agrégé des cinq pulls (diagnostic).
class EnrollmentPullsReport {
  final int updated;
  final int notModified;
  final int failed;

  const EnrollmentPullsReport({
    required this.updated,
    required this.notModified,
    required this.failed,
  });
}
