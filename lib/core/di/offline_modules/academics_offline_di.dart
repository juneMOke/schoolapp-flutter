import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
// ── Academics (offline) ──
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_cours_pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_handlers.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_notes_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/grades_referential_pull_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/grades_referential_pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/notes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/course_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/course_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/grades_referential_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/offline/sync_academics_pulls_usecase.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
// ── Schedule (offline) ──
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_api.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_pull_handler.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_offline_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/offline/schedule_pull_repository_impl.dart';

/// Registrar de la branche offline **Notes / Cours** (academics + schedule,
/// ADR-006). Appelé depuis `registerOfflineModules` APRÈS le socle et les
/// branches A/B. Le pull cours/sessions est scopé **enseignant dérivé du
/// token** (DF-K) — plus de dépendance à `ref_classrooms`/l'année courante
/// pour son itération.
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
  getIt.registerLazySingleton<GradesReferentialPullApi>(
    () => GradesReferentialPullApi(getIt<Dio>()),
  );

  // ── Repositories (pull résumables + écriture offline) ──
  getIt.registerLazySingleton<SchedulePullRepositoryImpl>(
    () => SchedulePullRepositoryImpl(
      api: getIt<SchedulePullApi>(),
      localDataSource: getIt<ScheduleRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
      // Partition par compte des caches cadrés prof (owner_scope.dart).
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<AcademicsCoursPullRepositoryImpl>(
    () => AcademicsCoursPullRepositoryImpl(
      api: getIt<AcademicsCoursPullApi>(),
      localDataSource: getIt<AcademicsRefLocalDataSource>(),
      academicsLocalDataSource: getIt<AcademicsLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<AcademicsMetierPullRepositoryImpl>(
    () => AcademicsMetierPullRepositoryImpl(
      api: getIt<AcademicsMetierPullApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      refLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<EvaluationOfflineRepositoryImpl>(
    () => EvaluationOfflineRepositoryImpl(
      localDataSource: getIt<AcademicsLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton<NotesOfflineRepositoryImpl>(
    () => NotesOfflineRepositoryImpl(
      localDataSource: getIt<AcademicsLocalDataSource>(),
      idGenerator: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  // Impl offline-first de ScheduleRepository (getMyTimetable local ; grille +
  // écritures admin déléguées à l'online concret). Rebindée dans injection.dart.
  getIt.registerLazySingleton<ScheduleOfflineRepositoryImpl>(
    () => ScheduleOfflineRepositoryImpl(
      online: getIt<ScheduleRepositoryImpl>(),
      refLocalDataSource: getIt<ScheduleRefLocalDataSource>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  // Impl offline-first de CourseRepository (getMyCourses local ; détail/création
  // délégués à l'online concret CourseRepositoryImpl). Rebindée dans injection.dart.
  getIt.registerLazySingleton<CourseOfflineRepositoryImpl>(
    () => CourseOfflineRepositoryImpl(
      online: getIt<CourseRepositoryImpl>(),
      academicsLocalDataSource: getIt<AcademicsLocalDataSource>(),
      academicsRefLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      classroomLocalDataSource: getIt<ClassroomLocalDataSource>(),
      evaluationRepository: getIt<EvaluationOfflineRepositoryImpl>(),
      syncMetaDao: getIt<SyncMetaDao>(),
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
  // Bundle `grades-referential` (ETag, cadré prof) : source du statut de
  // clôture / plafonds / chapitres, composés par `CourseOfflineRepositoryImpl.
  // getCoursNotationDetail`. Remplace l'ancien squelette `ref_cours_notation`
  // (workaround réutilisant un endpoint ONLINE, retiré).
  getIt.registerLazySingleton<GradesReferentialPullRepositoryImpl>(
    () => GradesReferentialPullRepositoryImpl(
      api: getIt<GradesReferentialPullApi>(),
      refLocalDataSource: getIt<AcademicsRefLocalDataSource>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // ── UseCases ──
  // Hydratation au montage des scopes academics/schedule. Elle reste nécessaire
  // à côté du cycle complet : celui-ci part à l'ouverture de session et au
  // retour online, et une tablette posée sur le Wi-Fi de l'école ne verra aucun
  // retour online de la journée.
  //
  // Une seule dépendance depuis le lot F6 : le use case ne porte plus que la
  // LISTE de ses ressources. Gardes (connectivité, crédentiels), permissions,
  // ordre et diffusion sur le `PullCompletionBus` sont passés dans le socle —
  // d'où la disparition d'`AuthSessionManager`, `ConnectivityService` et
  // `PullCompletionBus` de cette construction.
  getIt.registerFactory<SyncAcademicsPullsUseCase>(
    () => SyncAcademicsPullsUseCase(getIt<PullCoordinator>()),
  );

  // ── Handlers d'outbox (push, routés par aggregateType) ──
  getIt<SyncEngine>().registerHandler(
    EvaluationOutboxHandler(
      syncApi: getIt<AcademicsEvaluationSyncApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt<SyncEngine>().registerHandler(
    NotesBatchOutboxHandler(
      syncApi: getIt<AcademicsNotesSyncApi>(),
      localDataSource: getIt<AcademicsLocalDataSource>(),
      requiredAuth: requiredAuth,
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // ── Handlers de pull delta (routés par ressource) ──
  //
  // ⚠️ L'ORDRE D'ENREGISTREMENT EST L'ORDRE D'EXÉCUTION : le coordinateur itère
  // `_handlers.values`, et une `LinkedHashMap` conserve la position
  // d'insertion. Le référentiel de notes vient donc EN PREMIER — il était
  // enregistré dernier des six, à rebours du graphe de dépendances (ADR-015 K),
  // alors que le détail d'un cours et la composition des évaluations le lisent.
  //
  // Depuis le lot F6, c'est le SEUL endroit où cet ordre est décidé :
  // `SyncAcademicsPullsUseCase` en tenait une seconde copie, il ne fournit plus
  // qu'un ensemble de ressources et `pullSubset` les exécute dans l'ordre
  // ci-dessous. Le figer reste indispensable — cf.
  // `test/core/di/offline_pull_registration_order_test.dart`.
  getIt<PullCoordinator>().registerHandler(
    GradesReferentialPullHandler(getIt<GradesReferentialPullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    TimeSlotsPullHandler(getIt<SchedulePullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    SessionsPullHandler(getIt<SchedulePullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    AcademicsCoursPullHandler(getIt<AcademicsCoursPullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    EvaluationsPullHandler(getIt<AcademicsMetierPullRepositoryImpl>()),
  );
  getIt<PullCoordinator>().registerHandler(
    NotesPullHandler(getIt<AcademicsMetierPullRepositoryImpl>()),
  );
}
