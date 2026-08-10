import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// [PullHandler] des créneaux horaires (référence, scope école/JWT). Enregistré
/// sur le `PullCoordinator`. Le jeton vit dans `sync_meta` via le repository. Ne
/// lève pas : l'échec (`Left`) est traduit en [PullOutcome.error].
class TimeSlotsPullHandler implements PullHandler {
  final SchedulePullRepositoryImpl _repository;

  const TimeSlotsPullHandler(this._repository);

  @override
  String get resource => kScheduleTimeSlotsResource;

  /// GET /sync/schedule/time-slots — gardé sur `schedule.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.scheduleRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncTimeSlots();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}

/// [PullHandler] des séances récurrentes (référence, scope année active).
class SessionsPullHandler implements PullHandler {
  final SchedulePullRepositoryImpl _repository;

  const SessionsPullHandler(this._repository);

  @override
  String get resource => kScheduleSessionsResource;

  /// GET /sync/schedule/sessions — gardé sur `schedule.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.scheduleRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncSessions();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
