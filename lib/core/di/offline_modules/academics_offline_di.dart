import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';
// ── Academics (offline) ──
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_handlers.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_notes_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/notation_ref_pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/notes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_ref_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
// ── Schedule (offline) ──
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_api.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Registrar de la branche offline **Notes / Cours** (academics + schedule,
/// ADR-006). Appelé depuis `registerOfflineModules` APRÈS le socle et les
/// branches A/B (dépend de `ref_classrooms` — module Classe — pour l'itération
/// du pull cours, et de `BootstrapLocalRepository` pour l'année courante).
///
/// Ordre : DataSources → APIs → Repositories → Handlers (push sur `SyncEngine`,
/// pull sur `PullCoordinator`). Aucun BLoC ici : la présentation est branchée en
/// NF-7 sur les BLoCs online rapatriés.
void registerAcademicsOffline(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── DataSources locales ──
  getIt.registerLazySingleton<AcademicsLocalDataSource>(
    () => AcademicsLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<AcademicsRefLocalDataSource>(
    () => AcademicsRefLocalDataSource(getIt()),
  );
  getIt.registerLazySingleton<ScheduleRefLocalDataSource>(
    () => ScheduleRefLocalDataSource(getIt()),
  );

  // ── Clients Retrofit (pull + ingest) ──
  getIt.registerLazySingleton<SchedulePullApi>(
    () => SchedulePullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AcademicsCoursPullApi>(
    () => AcademicsCoursPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AcademicsMetierPullApi>(
    () => AcademicsMetierPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AcademicsEvaluationSyncApi>(
    () => AcademicsEvaluationSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AcademicsNotesSyncApi>(
    () => AcademicsNotesSyncApi(getIt<Dio>()),
  );

  // ── Repositories (pull résumables + écriture offline) ──
  getIt.registerLazySingleton<SchedulePullRepositoryImpl>(
    () => SchedulePullRepositoryImpl(
      api: getIt<SchedulePullApi>(),
      localDataSource: getIt<ScheduleRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<AcademicsCoursPullRepositoryImpl>(
    () => AcademicsCoursPullRepositoryImpl(
      api: getIt<AcademicsCoursPullApi>(),
      localDataSource: getIt<AcademicsRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<AcademicsMetierPullRepositoryImpl>(
    () => AcademicsMetierPullRepositoryImpl(
      api: getIt<AcademicsMetierPullApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      refLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt.registerLazySingleton<EvaluationOfflineRepositoryImpl>(
    () => EvaluationOfflineRepositoryImpl(
      localDataSource: getIt<AcademicsLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<NotesOfflineRepositoryImpl>(
    () => NotesOfflineRepositoryImpl(
      localDataSource: getIt<AcademicsLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  // Impl offline-first de NotationRepository (lecture composée notes+roster,
  // écriture → NotesOfflineRepositoryImpl). Rebindée sur NotationRepository dans
  // injection.dart.
  getIt.registerLazySingleton<NotationOfflineRepositoryImpl>(
    () => NotationOfflineRepositoryImpl(
      localDataSource: getIt<AcademicsLocalDataSource>(),
      refLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      rosterDataSource: getIt<ClassroomLocalDataSource>(),
      notesRepository: getIt<NotesOfflineRepositoryImpl>(),
    ),
  );
  // Réutilise le DataSource ONLINE (CourseRemoteDataSource) pour peupler le
  // cache des squelettes de notation — jamais l'interface rebindée offline.
  getIt.registerLazySingleton<NotationRefPullRepositoryImpl>(
    () => NotationRefPullRepositoryImpl(
      remoteDataSource: getIt<CourseRemoteDataSource>(),
      refLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── Handlers d'outbox (push, routés par aggregateType) ──
  getIt<SyncEngine>().registerHandler(
    EvaluationOutboxHandler(
      syncApi: getIt<AcademicsEvaluationSyncApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    NotesBatchOutboxHandler(
      syncApi: getIt<AcademicsNotesSyncApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── Handlers de pull delta (routés par ressource) ──
  getIt<PullCoordinator>().registerHandler(
    TimeSlotsPullHandler(getIt<SchedulePullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    SessionsPullHandler(getIt<SchedulePullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    AcademicsCoursPullHandler(
      repository: getIt<AcademicsCoursPullRepositoryImpl>(),
      bootstrapRepository: getIt<BootstrapLocalRepository>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    EvaluationsPullHandler(getIt<AcademicsMetierPullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    NotesPullHandler(getIt<AcademicsMetierPullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    NotationRefPullHandler(getIt<NotationRefPullRepositoryImpl>()),
  );
}
