import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/repositories/enrollment_suspension_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_pull_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_puller.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/repositories/enrollment_suspension_repository.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/usecases/enrollment_suspension_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/enrollment_suspension_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/open_suspensions_count_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspended_members_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La désactivation d'élèves : sa table, son flux, son envoi.
///
/// Enregistré après l'inscription et les classes : le geste dépend de
/// l'inscription (sonde `EnrollmentReadDao`), et sa projection touche les
/// membres de classe.
void registerEnrollmentSuspension(GetIt getIt) {
  getIt.registerLazySingleton<EnrollmentSuspensionChangeBus>(
    EnrollmentSuspensionChangeBus.new,
  );
  getIt.registerLazySingleton<EnrollmentSuspensionReadDao>(
    () => EnrollmentSuspensionReadDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentSuspensionWriteDao>(
    () => EnrollmentSuspensionWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentSuspensionSyncDao>(
    () => EnrollmentSuspensionSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentSuspensionApi>(
    () => EnrollmentSuspensionApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EnrollmentSuspensionRepository>(
    () => EnrollmentSuspensionRepositoryImpl(
      reader: getIt<EnrollmentSuspensionReadDao>(),
      writer: getIt<EnrollmentSuspensionWriteDao>(),
      bus: getIt<EnrollmentSuspensionChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton(
    () => SuspendStudentsUseCase(getIt<EnrollmentSuspensionRepository>()),
  );
  getIt.registerLazySingleton(
    () => ReactivateStudentsUseCase(getIt<EnrollmentSuspensionRepository>()),
  );
  getIt.registerLazySingleton(
    () => LoadOpenSuspensionsUseCase(getIt<EnrollmentSuspensionRepository>()),
  );
  getIt.registerLazySingleton(
    () => LoadEnrollmentSuspensionUseCase(
      getIt<EnrollmentSuspensionRepository>(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoadSuspendedMembersUseCase(getIt<EnrollmentSuspensionRepository>()),
  );
  getIt.registerLazySingleton(
    () =>
        ResolveSuspensionTargetUseCase(getIt<EnrollmentSuspensionRepository>()),
  );
  getIt.registerFactoryParam<OpenSuspensionsCountCubit, String, void>(
    (academicYearId, _) => OpenSuspensionsCountCubit(
      getIt<LoadOpenSuspensionsUseCase>(),
      academicYearId: academicYearId,
    ),
  );
  getIt.registerFactoryParam<SuspendedMembersCubit, String, void>(
    (academicYearId, _) => SuspendedMembersCubit(
      getIt<LoadSuspendedMembersUseCase>(),
      academicYearId: academicYearId,
    ),
  );
  getIt.registerFactoryParam<EnrollmentSuspensionStatusCubit, String, void>(
    (enrollmentId, _) => EnrollmentSuspensionStatusCubit(
      getIt<LoadEnrollmentSuspensionUseCase>(),
      enrollmentId: enrollmentId,
    ),
  );
  getIt.registerFactory<SuspensionGestureCubit>(
    () => SuspensionGestureCubit(
      suspend: getIt<SuspendStudentsUseCase>(),
      reactivate: getIt<ReactivateStudentsUseCase>(),
    ),
  );

  getIt<PullCoordinator>().registerHandler(
    EnrollmentSuspensionPullHandler(
      EnrollmentSuspensionPuller(
        api: getIt<EnrollmentSuspensionApi>(),
        runner: KeysetPullRunner(getIt<SyncMetaDao>()),
        sync: getIt<EnrollmentSuspensionSyncDao>(),
        bus: getIt<EnrollmentSuspensionChangeBus>(),
        currentUser: getIt<CurrentUserContext>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    ),
  );
  getIt<SyncEngine>().registerHandler(
    EnrollmentSuspensionOutboxHandler(
      api: getIt<EnrollmentSuspensionApi>(),
      sync: getIt<EnrollmentSuspensionSyncDao>(),
      outbox: OutboxDao(getIt<Database>()),
      dependency: (studentId, academicYearId) => getIt<EnrollmentReadDao>()
          .studentEnrollmentDependency(studentId, academicYearId),
      bus: getIt<EnrollmentSuspensionChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}
