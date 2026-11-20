import 'dart:async';

import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/online/calendar_online_api.dart';
import 'package:school_app_flutter/features/school_calendar/data/repositories/school_calendar_repository_impl.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_events_outbox_handler.dart';
import 'package:school_app_flutter/features/school_calendar/data/sync/calendar_pullers.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le calendrier scolaire — lecture 100 % locale par trois flux, écriture des
/// événements 100 % lot de synchro, web compris (A18). Créer, dupliquer et
/// publier sont les seuls appels en ligne.
void registerSchoolCalendar(GetIt getIt) {
  final db = getIt<Database>();
  final reference = CalendarReferenceDao(db);
  final events = CalendarEventDao(db);
  // Un remplacement de période accepté réécrit les dates des périodes, qui
  // descendent par le référentiel des notes (ETag) : le relire sans attendre.
  void periodsMoved() => unawaited(
    getIt<PullCoordinator>().pullSubset({
      ...resourcesOf(SyncPlanKeys.academicsGradesReferential),
    }),
  );
  for (final feed in [
    CalendarFeed.framework(reference),
    CalendarFeed.calendars(reference),
    CalendarFeed.events(events, onPeriodsMoved: periodsMoved),
  ]) {
    getIt<PullCoordinator>().registerHandler(
      CalendarPullHandler(
        feed: feed,
        dio: getIt<Dio>(),
        runner: KeysetPullRunner(getIt<SyncMetaDao>()),
        currentUser: getIt<CurrentUserContext>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    );
  }
  getIt<SyncEngine>().registerHandler(
    CalendarEventsOutboxHandler(
      dio: getIt<Dio>(),
      dao: events,
      outbox: OutboxDao(db),
      requiredAuth: getIt<Map<String, dynamic>>(),
      onPeriodsMoved: periodsMoved,
    ),
  );
  getIt.registerLazySingleton<SchoolCalendarRepository>(
    () => SchoolCalendarRepositoryImpl(
      db: db,
      online: CalendarOnlineApi(getIt<Dio>(), getIt<Map<String, dynamic>>()),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      coordinator: getIt<PullCoordinator>(),
      engine: getIt<SyncEngine>(),
    ),
  );
  // ── Écran : cubit en fabrique, jamais singleton ──
  getIt.registerFactory(
    () => SchoolCalendarCubit(
      getIt<SchoolCalendarRepository>(),
      schoolToday: () => SchoolTime.today(DateTime.now()),
    ),
  );
}
