import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
// ── Bootstrap (dépendance des pull handlers : année courante) ──
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
// ── Classe (offline) ──
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_outbox_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_pull_api.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_transfer_sync_api.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_transfer_pull_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/reassign_member_online_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/record_classroom_transfer_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';
// ── Présence (offline) ──
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_pull_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_local_attendance_rate_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_student_attendance_stats_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/record_daily_attendance_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_attendance_pull_usecase.dart';
// ── Discipline (offline) ──
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_case_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_pull_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_sync_api.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_case_offline_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/add_disciplinary_comment_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/create_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_comment_counts_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_comments_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_disciplinary_freshness_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_offline_disciplinary_cases_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/update_disciplinary_case_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/update_disciplinary_case_status_usecase.dart';
// ── BLoCs de présentation offline ──
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';

/// Registrar DI de la branche offline **Classe + Présence/Discipline**.
///
/// Appelé par `registerOfflineModules()` (offline_injection.dart), APRÈS les
/// features online (dont `ClassroomRepository`, `DisciplinaryCaseRemoteDataSource`
/// réutilisés ici) et le socle offline (base, outbox, moteur, IdGenerator).
///
/// Ordre : DataSources → Repositories → UseCases → Handlers d'outbox.
void registerClassroomAttendanceOffline(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── DataSources locales + clients de sync ──
  getIt.registerLazySingleton<ClassroomSyncApi>(
    () => ClassroomSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ClassroomTransferSyncApi>(
    () => ClassroomTransferSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ClassroomTransferPullApi>(
    () => ClassroomTransferPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ClassroomLocalDataSource>(
    () => ClassroomLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<AttendanceSyncApi>(
    () => AttendanceSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AttendancePullApi>(
    () => AttendancePullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<DisciplinarySyncApi>(
    () => DisciplinarySyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<DisciplinaryPullApi>(
    () => DisciplinaryPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<DisciplinaryLocalDataSource>(
    () => DisciplinaryLocalDataSource(getIt<Database>()),
  );

  // ── Repositories offline-first ──
  getIt.registerLazySingleton<ClassroomOfflineRepository>(
    () => ClassroomOfflineRepositoryImpl(
      syncApi: getIt<ClassroomSyncApi>(),
      localDataSource: getIt<ClassroomLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      idGenerator: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<ClassroomTransferPullRepository>(
    () => ClassroomTransferPullRepositoryImpl(
      api: getIt<ClassroomTransferPullApi>(),
      localDataSource: getIt<ClassroomLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<AttendanceOfflineRepository>(
    () => AttendanceOfflineRepositoryImpl(
      localDataSource: getIt<AttendanceLocalDataSource>(),
      rosterDataSource: getIt<ClassroomLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      idGenerator: getIt<IdGenerator>(),
    ),
  );
  getIt.registerLazySingleton<AttendancePullRepository>(
    () => AttendancePullRepositoryImpl(
      api: getIt<AttendancePullApi>(),
      localDataSource: getIt<AttendanceLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<DisciplinaryCaseOfflineRepository>(
    () => DisciplinaryCaseOfflineRepositoryImpl(
      localDataSource: getIt<DisciplinaryLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
    ),
  );
  getIt.registerLazySingleton<DisciplinaryPullRepository>(
    () => DisciplinaryPullRepositoryImpl(
      api: getIt<DisciplinaryPullApi>(),
      localDataSource: getIt<DisciplinaryLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── UseCases (factory) ──
  // Classe
  getIt.registerFactory<SyncClassroomsUseCase>(
    () => SyncClassroomsUseCase(getIt<ClassroomOfflineRepository>()),
  );
  getIt.registerFactory<GetOfflineClassroomsUseCase>(
    () => GetOfflineClassroomsUseCase(getIt<ClassroomOfflineRepository>()),
  );
  getIt.registerFactory<GetOfflineRosterUseCase>(
    () => GetOfflineRosterUseCase(getIt<ClassroomOfflineRepository>()),
  );
  getIt.registerFactory<GetComposedRostersUseCase>(
    () => GetComposedRostersUseCase(getIt<ClassroomOfflineRepository>()),
  );
  getIt.registerFactory<RecordClassroomTransferUseCase>(
    () => RecordClassroomTransferUseCase(getIt<ClassroomOfflineRepository>()),
  );
  // Affectation d'un non-réparti = distribution ONLINE (ADR-004) : ne peut pas
  // être un événement de transfert (le non-réparti n'est pas dans le miroir).
  getIt.registerFactory<ReassignMemberOnlineUseCase>(
    () => ReassignMemberOnlineUseCase(
      onlineRepository: getIt<ClassroomRepository>(),
      offlineRepository: getIt<ClassroomOfflineRepository>(),
    ),
  );
  // Présence
  getIt.registerFactory<LoadDailyAttendanceUseCase>(
    () => LoadDailyAttendanceUseCase(getIt<AttendanceOfflineRepository>()),
  );
  getIt.registerFactory<RecordDailyAttendanceOfflineUseCase>(
    () => RecordDailyAttendanceOfflineUseCase(
      getIt<AttendanceOfflineRepository>(),
    ),
  );
  getIt.registerFactory<GetLocalAttendanceRateUseCase>(
    () => GetLocalAttendanceRateUseCase(getIt<AttendanceOfflineRepository>()),
  );
  getIt.registerFactory<SyncAttendancePullUseCase>(
    () => SyncAttendancePullUseCase(getIt<AttendancePullRepository>()),
  );
  getIt.registerFactory<GetStudentAttendanceStatsUseCase>(
    () =>
        GetStudentAttendanceStatsUseCase(getIt<AttendanceOfflineRepository>()),
  );
  // Discipline
  getIt.registerFactory<CreateDisciplinaryCaseOfflineUseCase>(
    () => CreateDisciplinaryCaseOfflineUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<UpdateDisciplinaryCaseOfflineUseCase>(
    () => UpdateDisciplinaryCaseOfflineUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<GetOfflineDisciplinaryCasesUseCase>(
    () => GetOfflineDisciplinaryCasesUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<AddDisciplinaryCommentOfflineUseCase>(
    () => AddDisciplinaryCommentOfflineUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<GetDisciplinaryCommentsOfflineUseCase>(
    () => GetDisciplinaryCommentsOfflineUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<GetDisciplinaryCommentCountsOfflineUseCase>(
    () => GetDisciplinaryCommentCountsOfflineUseCase(
      getIt<DisciplinaryCaseOfflineRepository>(),
    ),
  );
  getIt.registerFactory<SyncDisciplinaryPullUseCase>(
    () => SyncDisciplinaryPullUseCase(getIt<DisciplinaryPullRepository>()),
  );
  getIt.registerFactory<GetDisciplinaryFreshnessOfflineUseCase>(
    () => GetDisciplinaryFreshnessOfflineUseCase(
      getIt<DisciplinaryPullRepository>(),
    ),
  );
  getIt.registerFactory<UpdateDisciplinaryCaseStatusUseCase>(
    () => UpdateDisciplinaryCaseStatusUseCase(
      getIt<DisciplinaryCaseRepository>(),
    ),
  );

  // ── BLoCs (registerFactory) ──
  getIt.registerFactory<ClassroomOfflineBloc>(
    () => ClassroomOfflineBloc(
      syncClassrooms: getIt<SyncClassroomsUseCase>(),
      getClassrooms: getIt<GetOfflineClassroomsUseCase>(),
      getRoster: getIt<GetOfflineRosterUseCase>(),
      getComposedRosters: getIt<GetComposedRostersUseCase>(),
      recordTransfer: getIt<RecordClassroomTransferUseCase>(),
      reassignMember: getIt<ReassignMemberOnlineUseCase>(),
    ),
  );
  getIt.registerFactory<AttendanceOfflineBloc>(
    () => AttendanceOfflineBloc(
      loadDaily: getIt<LoadDailyAttendanceUseCase>(),
      recordDaily: getIt<RecordDailyAttendanceOfflineUseCase>(),
      getRate: getIt<GetLocalAttendanceRateUseCase>(),
      getStudentStats: getIt<GetStudentAttendanceStatsUseCase>(),
    ),
  );
  getIt.registerFactory<DisciplinaryCaseOfflineBloc>(
    () => DisciplinaryCaseOfflineBloc(
      createCase: getIt<CreateDisciplinaryCaseOfflineUseCase>(),
      updateCase: getIt<UpdateDisciplinaryCaseOfflineUseCase>(),
      getCases: getIt<GetOfflineDisciplinaryCasesUseCase>(),
      getCommentCounts: getIt<GetDisciplinaryCommentCountsOfflineUseCase>(),
      getComments: getIt<GetDisciplinaryCommentsOfflineUseCase>(),
      addComment: getIt<AddDisciplinaryCommentOfflineUseCase>(),
      getFreshness: getIt<GetDisciplinaryFreshnessOfflineUseCase>(),
    ),
  );

  // ── Handlers d'outbox (routés par aggregateType sur le moteur de synchro) ──
  getIt<SyncEngine>().registerHandler(
    ClassroomTransferOutboxHandler(
      api: getIt<ClassroomTransferSyncApi>(),
      localDataSource: getIt<ClassroomLocalDataSource>(),
      extras: requiredAuth,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    AttendanceOutboxHandler(
      syncApi: getIt<AttendanceSyncApi>(),
      localDataSource: getIt<AttendanceLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    DisciplinaryCaseOutboxHandler(
      syncApi: getIt<DisciplinarySyncApi>(),
      localDataSource: getIt<DisciplinaryLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── Handlers de pull delta (routés par ressource sur le coordinateur) ──
  getIt<PullCoordinator>().registerHandler(
    ClassroomPullHandler(
      offlineRepository: getIt<ClassroomOfflineRepository>(),
      bootstrapRepository: getIt<BootstrapLocalRepository>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    ClassroomTransferPullHandler(getIt<ClassroomTransferPullRepository>()),
  );
  getIt<PullCoordinator>().registerHandler(
    AttendancePullHandler(getIt<AttendancePullRepository>()),
  );
  getIt<PullCoordinator>().registerHandler(
    DisciplinaryPullHandler(getIt<DisciplinaryPullRepository>()),
  );
}
