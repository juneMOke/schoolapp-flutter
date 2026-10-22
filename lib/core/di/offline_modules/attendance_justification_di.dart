import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/justification_decision_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/repository/justification/attendance_justification_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/justification/attendance_justification_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/justification/attendance_justification_use_cases.dart';
import 'package:school_app_flutter/features/attendances/presentation/justifications/bloc/justification_queue_cubit.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart'
    show kClassroomMembersResource;
import 'package:sqflite_common/sqlite_api.dart';

/// Les justifications d'absence des parents (portail parent, V182). Posé
/// après `registerClassPresence` : son handler de pull doit s'enregistrer
/// APRÈS ceux des classes, des rosters et de l'appel, dont il dépend.
void registerAttendanceJustifications(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();
  getIt.registerLazySingleton<AttendanceJustificationApi>(
    () => AttendanceJustificationApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AttendanceJustificationLocalDataSource>(
    () => AttendanceJustificationLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceJustificationRepository>(
    () => AttendanceJustificationRepositoryImpl(
      local: getIt<AttendanceJustificationLocalDataSource>(),
      fetcher: getIt<AttachmentFetcher>(),
      requiredAuth: requiredAuth,
      ids: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  getIt.registerFactory(
    () => LoadAttendanceJustificationsUseCase(
      getIt<AttendanceJustificationRepository>(),
    ),
  );
  getIt.registerFactory(
    () => DecideAttendanceJustificationUseCase(
      getIt<AttendanceJustificationRepository>(),
    ),
  );
  getIt.registerFactory(
    () => OpenJustificationAttachmentUseCase(
      getIt<AttendanceJustificationRepository>(),
    ),
  );
  getIt.registerFactory(
    () => AcknowledgeJustificationNoticeUseCase(
      getIt<AttendanceJustificationRepository>(),
    ),
  );

  // La décision part par la file (un geste, une entrée) et descend par le
  // pull.
  getIt<SyncEngine>().registerHandler(
    JustificationDecisionOutboxHandler(
      api: getIt<AttendanceJustificationApi>(),
      justifications: getIt<AttendanceJustificationLocalDataSource>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    AttendanceJustificationPullHandler(
      api: getIt<AttendanceJustificationApi>(),
      justifications: getIt<AttendanceJustificationLocalDataSource>(),
      runner: KeysetPullRunner(getIt<SyncMetaDao>()),
      requiredAuth: requiredAuth,
    ),
  );

  // BLoC en factory (règle n°2) : un cubit par écran ouvert.
  getIt.registerFactory<JustificationQueueCubit>(
    () => JustificationQueueCubit(
      load: getIt<LoadAttendanceJustificationsUseCase>(),
      decide: getIt<DecideAttendanceJustificationUseCase>(),
      attachment: getIt<OpenJustificationAttachmentUseCase>(),
      acknowledge: getIt<AcknowledgeJustificationNoticeUseCase>(),
      availability: getIt<AttachmentAvailabilityTracker>(),
      signals: ResourceSyncSignals(
        bus: getIt<PullCompletionBus>(),
        engine: getIt<SyncEngine>(),
        // La file lit les justifications, et le roster pour les nommer.
        watched: const {
          kAttendanceJustificationsResource,
          kClassroomMembersResource,
        },
        pull: () => getIt<PullCoordinator>().pullSubset(const {
          kAttendanceJustificationsResource,
        }),
      ),
    ),
  );
}
