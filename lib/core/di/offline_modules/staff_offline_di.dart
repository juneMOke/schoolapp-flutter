import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/di/offline_modules/staff_attendance_di.dart';
import 'package:school_app_flutter/core/di/offline_modules/staff_documents_di.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/hr_personnel/data/hr_staff_dashboard_api.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_args.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/hr_presence/data/hr_attendance_stats_api.dart';
import 'package:school_app_flutter/features/hr_presence/data/repositories/hr_attendance_stats_repository_impl.dart';
import 'package:school_app_flutter/features/hr_presence/domain/repositories/hr_attendance_stats_repository.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_personnel/data/repositories/hr_staff_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/repositories/hr_staff_dashboard_repository.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_list_report_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_stats_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_contract_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/di/offline_modules/payroll_di.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/load_staff_file_use_case.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_pull_handlers.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le fichier du personnel (RH, sous-module A) : ses tables locales, ses trois
/// descentes et, lot après lot, ses remontées et ses écrans.
///
/// Le module ne dépend d'aucun autre module métier. Les pièces exigées lui
/// arrivent par le référentiel, qui écrit `ref_staff_document_types` par un
/// seam résolvant [StaffDocumentTypeDao] paresseusement.
void registerStaffOffline(GetIt getIt) {
  registerStaffAttendanceStorage(getIt);
  getIt.registerLazySingleton<StaffMemberDao>(
    () => StaffMemberDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffMemberWriteDao>(
    () => StaffMemberWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffMemberSyncDao>(
    () => StaffMemberSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractDao>(
    () => StaffContractDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractWriteDao>(
    () => StaffContractWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractSyncDao>(
    () => StaffContractSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentDao>(
    () => StaffDocumentDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentTypeDao>(
    () => StaffDocumentTypeDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffSyncApi>(() => StaffSyncApi(getIt<Dio>()));

  // ── Lecture locale ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(
      members: getIt<StaffMemberDao>(),
      contracts: getIt<StaffContractDao>(),
      writer: getIt<StaffMemberWriteDao>(),
      documents: getIt<StaffDocumentDao>(),
      types: getIt<StaffDocumentTypeDao>(),
      syncMeta: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStaffFileUseCase>(
    () => LoadStaffFileUseCase(getIt<StaffRepository>()),
  );
  getIt.registerFactory<SaveStaffMemberUseCase>(
    () => SaveStaffMemberUseCase(getIt<StaffRepository>()),
  );
  getIt.registerFactory<LoadStaffMemberUseCase>(
    () => LoadStaffMemberUseCase(getIt<StaffRepository>()),
  );
  getIt.registerLazySingleton<StaffContractRepository>(
    () => StaffContractRepositoryImpl(
      contracts: getIt<StaffContractDao>(),
      writer: getIt<StaffContractWriteDao>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStaffContractsUseCase>(
    () => LoadStaffContractsUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<AddStaffContractUseCase>(
    () => AddStaffContractUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<CorrectStaffContractUseCase>(
    () => CorrectStaffContractUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<SyncStaffPullsUseCase>(
    () => SyncStaffPullsUseCase(getIt<PullCoordinator>()),
  );

  // ── Présentation ────────────────────────────────────────────────────────
  getIt.registerFactory<StaffSnapshotSource>(
    () => StaffSnapshotSource(
      load: getIt<LoadStaffFileUseCase>(),
      pulls: getIt<SyncStaffPullsUseCase>(),
      bus: getIt<PullCompletionBus>(),
      engine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<StaffFileCubit>(
    () => StaffFileCubit(source: getIt<StaffSnapshotSource>()),
  );
  // RH · Personnel : une instance par écran (tableau de bord, fichier), sur la
  // même lecture locale.
  getIt.registerFactory<HrPersonnelCubit>(
    () => HrPersonnelCubit(source: getIt<StaffSnapshotSource>()),
  );
  // RH · Personnel ▸ Tableau de bord : en ligne, sur les trois routes
  // `/hr/staff-stats` — chiffres, liste et PDF à la même source.
  getIt.registerLazySingleton<HrStaffDashboardApi>(
    () => HrStaffDashboardApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<HrStaffDashboardRepository>(
    () => HrStaffDashboardRepositoryImpl(
      api: getIt<HrStaffDashboardApi>(),
      connectivity: getIt<ConnectivityService>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt.registerFactory<GetHrStaffStatsUseCase>(
    () => GetHrStaffStatsUseCase(getIt<HrStaffDashboardRepository>()),
  );
  getIt.registerFactory<GetHrStaffMembersUseCase>(
    () => GetHrStaffMembersUseCase(getIt<HrStaffDashboardRepository>()),
  );
  getIt.registerFactory<GetHrStaffListReportUseCase>(
    () => GetHrStaffListReportUseCase(getIt<HrStaffDashboardRepository>()),
  );
  // RH · Présences : statistiques en ligne seulement (D1) — tableau de bord,
  // détail d'un agent, fiche, récapitulatif et PDF sur `/hr/attendance-stats`.
  // Le registre du jour reste sur le Pointage local.
  getIt.registerLazySingleton<HrAttendanceStatsApi>(
    () => HrAttendanceStatsApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<HrAttendanceStatsRepository>(
    () => HrAttendanceStatsRepositoryImpl(
      api: getIt<HrAttendanceStatsApi>(),
      connectivity: getIt<ConnectivityService>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt.registerFactory<GetHrAttendanceDashboardUseCase>(
    () => GetHrAttendanceDashboardUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<GetHrAttendanceAgentMonthUseCase>(
    () =>
        GetHrAttendanceAgentMonthUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<GetHrAttendanceAgentYearUseCase>(
    () => GetHrAttendanceAgentYearUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<GetHrAttendanceProfilesUseCase>(
    () => GetHrAttendanceProfilesUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<GetHrAttendanceRecapUseCase>(
    () => GetHrAttendanceRecapUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<GetHrAttendanceReportUseCase>(
    () => GetHrAttendanceReportUseCase(getIt<HrAttendanceStatsRepository>()),
  );
  getIt.registerFactory<HrPresenceDashboardCubit>(
    () => HrPresenceDashboardCubit(
      getDashboard: getIt<GetHrAttendanceDashboardUseCase>(),
      countUnsynced: getIt<CountUnsyncedStaffAttendanceUseCase>(),
      signals: getIt<StaffSyncSignals>(),
    ),
  );
  getIt.registerFactoryParam<
    HrPresenceAgentMonthCubit,
    HrPresenceAgentArgs,
    void
  >(
    (args, _) => HrPresenceAgentMonthCubit(
      getMonth: getIt<GetHrAttendanceAgentMonthUseCase>(),
      source: getIt<StaffSnapshotSource>(),
      agentId: args.agentId,
      month: args.month,
      yearStart: args.yearStart,
    ),
  );
  getIt.registerFactoryParam<HrPresenceProfilesCubit, DateTime?, void>(
    (yearStart, _) => HrPresenceProfilesCubit(
      getProfiles: getIt<GetHrAttendanceProfilesUseCase>(),
      yearStart: yearStart,
    ),
  );
  getIt.registerFactoryParam<HrPresenceFicheCubit, HrPresenceFicheArgs, void>(
    (args, _) => HrPresenceFicheCubit(
      getMonth: getIt<GetHrAttendanceAgentMonthUseCase>(),
      getYear: getIt<GetHrAttendanceAgentYearUseCase>(),
      source: getIt<StaffSnapshotSource>(),
      args: args,
    ),
  );
  getIt.registerFactoryParam<HrPresenceRecapCubit, DateTime?, void>(
    (yearStart, _) => HrPresenceRecapCubit(
      getRecap: getIt<GetHrAttendanceRecapUseCase>(),
      loadLocal: getIt<LoadStaffAttendanceUseCase>(),
      countUnsynced: getIt<CountUnsyncedStaffAttendanceUseCase>(),
      commands: getIt<StaffAttendanceCommands>(),
      signals: getIt<StaffSyncSignals>(),
      yearStart: yearStart,
    ),
  );
  getIt.registerFactory<HrAttendanceReportCubit>(
    () => HrAttendanceReportCubit(
      getReport: getIt<GetHrAttendanceReportUseCase>(),
    ),
  );
  getIt.registerFactory<HrStaffStatsCubit>(
    () => HrStaffStatsCubit(getStats: getIt<GetHrStaffStatsUseCase>()),
  );
  getIt.registerFactory<HrStaffMembersCubit>(
    () => HrStaffMembersCubit(getMembers: getIt<GetHrStaffMembersUseCase>()),
  );
  getIt.registerFactory<HrStaffListReportCubit>(
    () =>
        HrStaffListReportCubit(getReport: getIt<GetHrStaffListReportUseCase>()),
  );
  getIt.registerFactory<StaffContractsCubit>(
    () => StaffContractsCubit(
      load: getIt<LoadStaffContractsUseCase>(),
      add: getIt<AddStaffContractUseCase>(),
      correct: getIt<CorrectStaffContractUseCase>(),
    ),
  );

  // ── Descente ────────────────────────────────────────────────────────────
  // Trois flux, trois droits : le plan n'annonce à une tablette que ce que son
  // compte a le droit de lire, et le coordinateur ne tire que ce qui est
  // annoncé.
  getIt.registerLazySingleton<StaffPullRepository>(
    () => StaffPullRepositoryImpl(
      api: getIt<StaffSyncApi>(),
      runner: KeysetPullRunner(getIt<SyncMetaDao>()),
      members: getIt<StaffMemberDao>(),
      contracts: getIt<StaffContractDao>(),
      documents: getIt<StaffDocumentDao>(),
      attendanceApi: getIt<StaffAttendanceSyncApi>(),
      attendance: getIt<StaffAttendanceDao>(),
      locks: getIt<StaffAttendanceLockDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  final coordinator = getIt<PullCoordinator>();
  final pulls = getIt<StaffPullRepository>();
  coordinator.registerHandler(StaffPullHandler.members(pulls));
  coordinator.registerHandler(StaffPullHandler.contracts(pulls));
  coordinator.registerHandler(StaffPullHandler.documents(pulls));
  coordinator.registerHandler(StaffPullHandler.attendance(pulls));
  coordinator.registerHandler(StaffPullHandler.attendanceLocks(pulls));

  // ── Remontée → SyncEngine ───────────────────────────────────────────────
  // Trois gestes, trois entrées : la pose d'un contrat attend l'accusé de sa
  // fiche, la correction celui de la période corrigée (`blocked`).
  final engine = getIt<SyncEngine>();
  engine.registerHandler(
    StaffMemberOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffMemberSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  engine.registerHandler(
    StaffContractOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffContractSyncDao>(),
      members: getIt<StaffMemberDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  engine.registerHandler(
    StaffContractCorrectionOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffContractSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );

  registerStaffDocuments(getIt);
  registerStaffAttendance(getIt);
  registerPayroll(getIt);
}
