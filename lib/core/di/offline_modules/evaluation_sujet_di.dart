import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_child_outbox_support.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_copie_log_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_sujet_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_copie_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_sujet_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_copie_repository.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_publication_repository.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_publication_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

/// Registrar du **sujet d'une évaluation** (plan front EV) : sujet, copie,
/// publications. Appelé à la fin de `registerAcademicsOffline` : il s'appuie
/// sur la base d'école et le moteur de synchro déjà enregistrés.
///
/// Ordre : DataSources → API → applicateur du delta → Repositories →
/// handlers d'outbox.
void registerEvaluationSujet(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── DataSources locales ──
  getIt.registerLazySingleton<EvaluationSujetLocalDataSource>(
    () => EvaluationSujetLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<EvaluationCopieLogLocalDataSource>(
    () => EvaluationCopieLogLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<EvaluationPublicationLocalDataSource>(
    () => EvaluationPublicationLocalDataSource(getIt()),
  );

  // ── Client Retrofit (sujet, journal, publications) ──
  getIt.registerLazySingleton<AcademicsEvaluationSujetApi>(
    () => AcademicsEvaluationSujetApi(getIt<Dio>()),
  );

  // ── Application d'une évaluation vue du serveur (pull, réponses) ──
  getIt.registerLazySingleton<EvaluationViewApplier>(
    () => EvaluationViewApplier(
      db: getIt<Database>(),
      academics: getIt<AcademicsLocalDataSource>(),
      sujets: getIt<EvaluationSujetLocalDataSource>(),
      copieLog: getIt<EvaluationCopieLogLocalDataSource>(),
      publications: getIt<EvaluationPublicationLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<EvaluationChildOutboxSupport>(
    () => EvaluationChildOutboxSupport(
      academics: getIt<AcademicsLocalDataSource>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // ── Repositories ──
  getIt.registerLazySingleton<EvaluationSujetRepository>(
    () => EvaluationSujetRepositoryImpl(
      localDataSource: getIt<EvaluationSujetLocalDataSource>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  getIt.registerLazySingleton<EvaluationCopieRepository>(
    () => EvaluationCopieRepositoryImpl(
      localDataSource: getIt<EvaluationCopieLogLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  // Publications : en ligne, jamais par l'outbox.
  getIt.registerLazySingleton<EvaluationPublicationRepository>(
    () => EvaluationPublicationRepositoryImpl(
      api: getIt<AcademicsEvaluationSujetApi>(),
      publications: getIt<EvaluationPublicationLocalDataSource>(),
      academics: getIt<AcademicsLocalDataSource>(),
      sujets: getIt<EvaluationSujetLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── Handlers d'outbox (push, routés par aggregateType) ──
  getIt<SyncEngine>().registerHandler(
    EvaluationSujetOutboxHandler(
      api: getIt<AcademicsEvaluationSujetApi>(),
      sujets: getIt<EvaluationSujetLocalDataSource>(),
      views: getIt<EvaluationViewApplier>(),
      support: getIt<EvaluationChildOutboxSupport>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    EvaluationCopieLogOutboxHandler(
      api: getIt<AcademicsEvaluationSujetApi>(),
      copieLog: getIt<EvaluationCopieLogLocalDataSource>(),
      views: getIt<EvaluationViewApplier>(),
      support: getIt<EvaluationChildOutboxSupport>(),
      requiredAuth: requiredAuth,
    ),
  );
}
