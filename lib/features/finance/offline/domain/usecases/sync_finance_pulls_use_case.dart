import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_pull_repository.dart';

/// Tire les deux ressources pull du grand-livre (créances, paiements) — déclenché
/// au montage du module Facturation, en plus du cycle global du `PullCoordinator`
/// (retour online). Le montage est le moment d'hydratation : le caissier ouvre la
/// Facturation **pendant** qu'il a du réseau, avant de partir encaisser hors-ligne.
///
/// Best-effort : aucun échec n'est propagé — le cache local reste en l'état ; le
/// bilan agrège les compteurs pour un éventuel diagnostic.
///
/// ⚠️ Les deux pulls ne sont PAS isolés : les paiements **dépendent** des
/// créances. Un ordre seul ne suffit pas, il faut une GARDE — tirer les
/// paiements par-dessus un miroir de créances périmé est le sens de panne qui
/// fait réencaisser (cf. le ⚠️ de `registerEnrollmentFinanceOffline`, et
/// `FinanceLedgerRefresher` qui applique la même règle). Créances KO ⇒ on
/// n'essaie même pas les paiements.
class SyncFinancePullsUseCase {
  final FinancePullRepository _repository;

  const SyncFinancePullsUseCase(this._repository);

  Future<FinancePullsReport> call() async {
    var updated = 0, notModified = 0;

    void tally(FinancePullOutcome outcome) =>
        outcome.notModified ? notModified++ : updated++;

    final charges = await _repository.syncStudentCharges();
    if (charges.isLeft()) {
      // Paiements NON tentés (garde, pas un échec de leur part).
      return const FinancePullsReport(
        updated: 0,
        notModified: 0,
        failed: 1,
        skipped: 1,
      );
    }
    charges.fold((_) {}, tally);

    var failed = 0;
    (await _repository.syncPayments()).fold((_) => failed++, tally);

    return FinancePullsReport(
      updated: updated,
      notModified: notModified,
      failed: failed,
    );
  }
}

/// Bilan agrégé des deux pulls (diagnostic).
class FinancePullsReport {
  final int updated;
  final int notModified;
  final int failed;

  /// Pulls non tentés parce qu'une dépendance a échoué (créances KO ⇒ paiements
  /// sautés). Distinct de [failed] : rien n'a été demandé au serveur.
  final int skipped;

  const FinancePullsReport({
    required this.updated,
    required this.notModified,
    required this.failed,
    this.skipped = 0,
  });
}
