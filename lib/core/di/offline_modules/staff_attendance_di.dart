import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_settings_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_attendance_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_local_writer.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le stockage du Pointage (RH, sous-module B) : ses DAO et son API. Posé
/// **avant** la descente du module RH, qui tire aussi ses deux flux.
void registerStaffAttendanceStorage(GetIt getIt) {
  getIt.registerLazySingleton<StaffAttendanceDao>(
    () => StaffAttendanceDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffAttendanceWriteDao>(
    () => StaffAttendanceWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffAttendanceSyncDao>(
    () => StaffAttendanceSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffAttendanceLockDao>(
    () => StaffAttendanceLockDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffAttendanceSettingsDao>(
    () => StaffAttendanceSettingsDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffAttendanceSyncApi>(
    () => StaffAttendanceSyncApi(getIt<Dio>()),
  );
}

/// Le Pointage : son dépôt, ses cas d'usage, ses trois remontées. Appelé par
/// `registerStaffOffline`, qui a déjà posé le fichier du personnel dont il lit
/// les agents.
void registerStaffAttendance(GetIt getIt) {
  getIt.registerLazySingleton<StaffAttendanceRepository>(
    () => StaffAttendanceRepositoryImpl(
      staff: getIt<StaffRepository>(),
      records: getIt<StaffAttendanceDao>(),
      writer: getIt<StaffAttendanceWriteDao>(),
      locks: getIt<StaffAttendanceLockDao>(),
      settings: getIt<StaffAttendanceSettingsDao>(),
      contracts: getIt<StaffContractDao>(),
      local: StaffLocalWriter(
        currentUser: getIt<CurrentUserContext>(),
        syncEngine: getIt<SyncEngine>(),
      ),
      ids: getIt<IdGenerator>(),
    ),
  );
  getIt.registerFactory<LoadStaffAttendanceUseCase>(
    () => LoadStaffAttendanceUseCase(getIt<StaffAttendanceRepository>()),
  );
  getIt.registerFactory<SaveStaffAttendanceUseCase>(
    () => SaveStaffAttendanceUseCase(getIt<StaffAttendanceRepository>()),
  );
  getIt.registerFactory<RecordStaffAttendanceGestureUseCase>(
    () =>
        RecordStaffAttendanceGestureUseCase(getIt<StaffAttendanceRepository>()),
  );
  getIt.registerFactory<SaveStaffAttendanceSettingsUseCase>(
    () =>
        SaveStaffAttendanceSettingsUseCase(getIt<StaffAttendanceRepository>()),
  );
  getIt.registerFactory<StaffSyncSignals>(
    () => StaffSyncSignals(
      pulls: SyncStaffPullsUseCase(
        getIt<PullCoordinator>(),
        resources: SyncStaffPullsUseCase.attendanceResources,
      ),
      bus: getIt<PullCompletionBus>(),
      engine: getIt<SyncEngine>(),
    ),
  );

  // ── Présentation ────────────────────────────────────────────────────────
  getIt.registerFactory<StaffAttendanceCommands>(
    () => StaffAttendanceCommands(
      save: getIt<SaveStaffAttendanceUseCase>(),
      gesture: getIt<RecordStaffAttendanceGestureUseCase>(),
      settings: getIt<SaveStaffAttendanceSettingsUseCase>(),
    ),
  );
  getIt.registerFactory<StaffAttendanceCubit>(
    () => StaffAttendanceCubit(
      load: getIt<LoadStaffAttendanceUseCase>(),
      signals: getIt<StaffSyncSignals>(),
      commands: getIt<StaffAttendanceCommands>(),
    ),
  );

  // ── Remontée → SyncEngine ───────────────────────────────────────────────
  // Trois agrégats : le pointage (attend sa fiche et une réouverture en vol),
  // le geste de verrou (attend ses aînés et les pointages de sa période), les
  // réglages.
  final engine = getIt<SyncEngine>();
  final extras = getIt<Map<String, dynamic>>();
  engine.registerHandler(
    StaffAttendanceOutboxHandler(
      api: getIt<StaffAttendanceSyncApi>(),
      dao: getIt<StaffAttendanceSyncDao>(),
      locks: getIt<StaffAttendanceLockDao>(),
      members: getIt<StaffMemberDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: extras,
    ),
  );
  engine.registerHandler(
    StaffAttendanceGestureOutboxHandler(
      api: getIt<StaffAttendanceSyncApi>(),
      locks: getIt<StaffAttendanceLockDao>(),
      records: getIt<StaffAttendanceDao>(),
      recordSync: getIt<StaffAttendanceSyncDao>(),
      members: getIt<StaffMemberDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: extras,
    ),
  );
  engine.registerHandler(
    StaffAttendanceSettingsOutboxHandler(
      api: getIt<StaffAttendanceSyncApi>(),
      dao: getIt<StaffAttendanceSettingsDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: extras,
    ),
  );
}
