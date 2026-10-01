import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';

/// Ce qui périme une lecture RH, partagé par le fichier du personnel et le
/// Pointage : les flux RH, plus le socle (réglages, pièces exigées, année).
class StaffSyncSignals extends ResourceSyncSignals {
  StaffSyncSignals({
    required SyncStaffPullsUseCase pulls,
    required super.bus,
    required super.engine,
  }) : super(
         pull: pulls.call,
         watched: {
           ...pulls.watched,
           ...resourcesOf(SyncPlanKeys.schoolReferential),
         },
       );

  /// Les flux de l'écran, plus le socle.
  Set<String> get watchedResources => watched;
}
