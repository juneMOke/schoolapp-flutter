import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_sync_api.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_write_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/repositories/cotes_repository_impl.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';

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
  getIt<SyncEngine>().registerHandler(
    CotesBatchOutboxHandler(
      api: getIt<CotesSyncApi>(),
      localDataSource: getIt<CotesWriteLocalDataSource>(),
      outbox: getIt<OutboxDao>(),
      requiredAuth: requiredAuth,
    ),
  );
}
