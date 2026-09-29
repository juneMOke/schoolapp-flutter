import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';

/// Hydrate le fichier du personnel au montage de ses écrans (ADR-015 F6) —
/// **par le coordinateur**, jamais en tirant le dépôt en direct : il reste seul
/// à connaître l'ordre, les droits et le plan. Un flux que le plan n'annonce
/// pas à ce compte (les montants, les pièces) n'est simplement pas tiré.
class SyncStaffPullsUseCase {
  final PullCoordinator _coordinator;

  const SyncStaffPullsUseCase(this._coordinator);

  static const Set<String> resources = {
    kStaffMembersResource,
    kStaffContractsResource,
    kStaffDocumentsResource,
  };

  Future<PullRunReport> call() => _coordinator.pullSubset(resources);
}
