import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
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
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_pull_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_puller.dart';
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
