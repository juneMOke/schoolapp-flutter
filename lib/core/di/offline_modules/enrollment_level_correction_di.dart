import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/level_correction_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/repositories/level_correction_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_api.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/repositories/level_correction_repository.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce qu'une correction accusée a changé au serveur, et que la tablette doit
/// redescendre. Les pierres tombales (créances supprimées) sont jointes d'office
/// par `PullCoordinator.pullSubset`.
const Set<String> kLevelCorrectionRefreshResources = {
  EnrollmentPullRepositoryImpl.deltaResource,
  FinancePullRepositoryImpl.chargesResource,
  kClassroomMembersResource,
};

/// La correction de niveau : sa table, son envoi.
///
/// Enregistrée après l'inscription, la finance et les classes : le geste dépend
/// de l'inscription (sonde `EnrollmentReadDao`), et son accusé redescend leurs
/// flux.
void registerEnrollmentLevelCorrection(GetIt getIt) {
  getIt.registerLazySingleton<LevelCorrectionChangeBus>(
    LevelCorrectionChangeBus.new,
  );
  getIt.registerLazySingleton<LevelCorrectionReadDao>(
    () => LevelCorrectionReadDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<LevelCorrectionWriteDao>(
    () => LevelCorrectionWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<LevelCorrectionSyncDao>(
    () => LevelCorrectionSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<LevelCorrectionApi>(
    () => LevelCorrectionApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LevelCorrectionRepository>(
    () => LevelCorrectionRepositoryImpl(
      reader: getIt<LevelCorrectionReadDao>(),
      writer: getIt<LevelCorrectionWriteDao>(),
      bus: getIt<LevelCorrectionChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CorrectLevelUseCase(getIt<LevelCorrectionRepository>()),
  );
  getIt.registerLazySingleton(
    () => LoadLevelCorrectionUseCase(getIt<LevelCorrectionRepository>()),
  );
  getIt.registerLazySingleton(
    () => IsCollectionHeldByLevelCorrectionUseCase(
      getIt<LevelCorrectionRepository>(),
    ),
  );

  getIt<SyncEngine>().registerHandler(
    LevelCorrectionOutboxHandler(
      api: getIt<LevelCorrectionApi>(),
      sync: getIt<LevelCorrectionSyncDao>(),
      outbox: OutboxDao(getIt<Database>()),
      dependency: (studentId, academicYearId) => getIt<EnrollmentReadDao>()
          .studentEnrollmentDependency(studentId, academicYearId),
      bus: getIt<LevelCorrectionChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
      refresh: () =>
          getIt<PullCoordinator>().pullSubset(kLevelCorrectionRefreshResources),
    ),
  );
}
