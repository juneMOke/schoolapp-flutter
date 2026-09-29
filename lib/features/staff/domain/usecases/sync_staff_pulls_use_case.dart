import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';

/// Hydrate le fichier du personnel au montage de ses écrans (ADR-015 F6) —
/// **par le coordinateur**, jamais en tirant le dépôt en direct : il reste seul
/// à connaître l'ordre, les droits et le plan. Un flux que le plan n'annonce
/// pas à ce compte (les montants, les pièces) n'est simplement pas tiré.
///
/// Un écran annonce les flux qu'il lit : le fichier ([resources]), le
/// Pointage ([attendanceResources]).
class SyncStaffPullsUseCase {
  final PullCoordinator _coordinator;
  final Set<String> _resources;

  const SyncStaffPullsUseCase(
    this._coordinator, {
    Set<String> resources = SyncStaffPullsUseCase.resources,
  }) : _resources = resources;

  static const Set<String> resources = {
    kStaffMembersResource,
    kStaffContractsResource,
    kStaffDocumentsResource,
  };

  /// Le Pointage lit les agents (et leur taux, quand le plan l'annonce), ses
  /// pointages et ses verrous.
  static const Set<String> attendanceResources = {
    kStaffMembersResource,
    kStaffContractsResource,
    kStaffAttendanceResource,
    kStaffAttendanceLocksResource,
  };

  Set<String> get watched => _resources;

  Future<PullRunReport> call() => _coordinator.pullSubset(_resources);
}
