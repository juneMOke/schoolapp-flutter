import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_pull_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_sync_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/ref_cote_cours_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/repositories/cotes_pull_repository_impl.dart';
import 'package:school_app_flutter/features/cotes/data/repositories/cotes_repository_impl.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Registrar de la saisie des notes par classe : chargement en ligne mis en
/// cache, écriture 100 % outbox. Les blocs sont dans `injection.dart`.
void registerCotes(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  getIt.registerLazySingleton<CotesLocalDataSource>(
    () => CotesLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<CotesWriteLocalDataSource>(
    () => CotesWriteLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<CotesApi>(() => CotesApi(getIt<Dio>()));
  getIt.registerLazySingleton<CotesSyncApi>(() => CotesSyncApi(getIt<Dio>()));
  getIt.registerLazySingleton<CotesRepository>(
    () => CotesRepositoryImpl(
      api: getIt<CotesApi>(),
      localDataSource: getIt<CotesLocalDataSource>(),
      writeDataSource: getIt<CotesWriteLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      connectivity: getIt<ConnectivityService>(),
      outbox: getIt<OutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<RefCoteCoursLocalDataSource>(
    () => RefCoteCoursLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<CotesPullApi>(() => CotesPullApi(getIt<Dio>()));
  getIt.registerLazySingleton<CotesPullRepositoryImpl>(
    () => CotesPullRepositoryImpl(
      api: getIt<CotesPullApi>(),
      localDataSource: getIt<RefCoteCoursLocalDataSource>(),
      puller: getIt<PerCoursKeysetPuller>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    CotesBatchOutboxHandler(
      api: getIt<CotesSyncApi>(),
      localDataSource: getIt<CotesWriteLocalDataSource>(),
      outbox: OutboxDao(getIt<Database>()),
      requiredAuth: requiredAuth,
    ),
  );
  // Après les notes : ce flux itère les mêmes cours locaux.
  getIt<PullCoordinator>().registerHandler(
    CotesPullHandler(getIt<CotesPullRepositoryImpl>()),
  );
  getIt<CoursEviction>().register(
    cursorPrefix: kAcademicsCotesResourcePrefix,
    evict: (coursId) =>
        getIt<RefCoteCoursLocalDataSource>().evictCours(coursId),
  );
}
