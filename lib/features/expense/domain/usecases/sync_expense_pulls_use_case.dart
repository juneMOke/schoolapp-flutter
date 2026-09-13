import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';

/// Hydrate le module au montage de ses écrans (ADR-015 F6) — **par le
/// coordinateur**, jamais en tirant le dépôt en direct : il reste seul à
/// connaître l'ordre, les droits et le plan.
///
/// Deux ressources : le registre, et le taux du jour, qui bouge chaque jour
/// et nourrit la lecture en dollars. Les types viennent du socle, déjà tiré à
/// l'ouverture de session.
class SyncExpensePullsUseCase {
  final PullCoordinator _coordinator;

  const SyncExpensePullsUseCase(this._coordinator);

  static final Set<String> resources = {
    kExpensesResource,
    ...resourcesOf(SyncPlanKeys.financeExchangeRates),
  };

  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
