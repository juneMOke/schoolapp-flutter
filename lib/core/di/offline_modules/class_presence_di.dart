import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart'
    show kAttendanceResource;
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_commands.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart'
    show kClassroomMembersResource;
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_draft_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_history_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/register/class_presence_use_cases.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_pull_handler.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:dio/dio.dart';

/// Le registre d'appel d'une classe (Présences des élèves v2). Posé après
/// `registerClassroomAttendanceOffline`, dont il réutilise le stockage de
/// l'appel, le roster et la file d'envoi.
void registerClassPresence(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();
  getIt.registerLazySingleton<AttendanceClosureApi>(
    () => AttendanceClosureApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AttendanceDraftLocalDataSource>(
    () => AttendanceDraftLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceClosureLocalDataSource>(
    () => AttendanceClosureLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<PresenceScheduleReader>(
    () => PresenceScheduleReader(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceDayWriter>(
    () => AttendanceDayWriter(
      localDataSource: getIt<AttendanceLocalDataSource>(),
      rosterDataSource: getIt<ClassroomLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton<ClassPresenceRepository>(
    () => ClassPresenceRepositoryImpl(
      sessions: getIt<AttendanceLocalDataSource>(),
      history: getIt<AttendanceHistoryLocalDataSource>(),
      drafts: getIt<AttendanceDraftLocalDataSource>(),
      closures: getIt<AttendanceClosureLocalDataSource>(),
      roster: getIt<ClassroomLocalDataSource>(),
      scheduleReader: getIt<PresenceScheduleReader>(),
      outbox: OutboxDao(getIt<Database>()),
      writer: getIt<AttendanceDayWriter>(),
      ids: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  getIt.registerFactory(
    () => LoadClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => SaveClassPresenceMarksUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => ValidateClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => ReopenClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => RetryClassPresenceDayUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => LoadClassPresenceMonthUseCase(getIt<ClassPresenceRepository>()),
  );
  getIt.registerFactory(
    () => CloseClassPresenceMonthUseCase(getIt<ClassPresenceRepository>()),
  );

  // La clôture part par la file (un geste, une entrée) et descend par le pull.
  getIt<SyncEngine>().registerHandler(
    AttendanceClosureOutboxHandler(
      api: getIt<AttendanceClosureApi>(),
      closures: getIt<AttendanceClosureLocalDataSource>(),
      outbox: OutboxDao(getIt<Database>()),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    AttendanceClosurePullHandler(
      api: getIt<AttendanceClosureApi>(),
      closures: getIt<AttendanceClosureLocalDataSource>(),
      runner: KeysetPullRunner(getIt<SyncMetaDao>()),
      requiredAuth: requiredAuth,
    ),
  );

  // BLoC en factory (règle n°2) : un cubit par écran ouvert.
  getIt.registerFactory<ClassPresenceCubit>(
    () => ClassPresenceCubit(
      load: getIt<LoadClassPresenceDayUseCase>(),
      loadMonth: getIt<LoadClassPresenceMonthUseCase>(),
      signals: ResourceSyncSignals(
        bus: getIt<PullCompletionBus>(),
        engine: getIt<SyncEngine>(),
        // L'appel lit l'appel, le roster, et l'horaire du socle.
        watched: {
          kAttendanceResource,
          kAttendanceClosuresResource,
          kClassroomMembersResource,
          ...resourcesOf(SyncPlanKeys.schoolReferential),
        },
        pull: () => getIt<PullCoordinator>().pullSubset(const {
          kAttendanceResource,
          kAttendanceClosuresResource,
        }),
      ),
      commands: ClassPresenceCommands(
        save: getIt<SaveClassPresenceMarksUseCase>(),
        validate: getIt<ValidateClassPresenceDayUseCase>(),
        reopen: getIt<ReopenClassPresenceDayUseCase>(),
        retry: getIt<RetryClassPresenceDayUseCase>(),
        close: getIt<CloseClassPresenceMonthUseCase>(),
      ),
    ),
  );
}
