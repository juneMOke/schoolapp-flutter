import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/di/offline_modules/class_journal_presentation_di.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_handlers.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_pull_writer.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_purge.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_sync_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_write_dao.dart';
import 'package:school_app_flutter/features/class_journal/data/repositories/journal_pull_repository.dart';
import 'package:school_app_flutter/features/class_journal/data/repositories/journal_repository_impl.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_outbox_handler.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_sync_api.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_sync_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le journal de classe (Cours ▸ Mon journal) : lecture 100 % locale, écriture
/// 100 % outbox. Appelé APRÈS [registerCourseProgramme] : une entrée qui cite
/// un chapitre attend son accusé, que seul le programme connaît.
void registerClassJournal(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── Local ──
  getIt
    ..registerLazySingleton<JournalDao>(() => JournalDao(getIt<Database>()))
    ..registerLazySingleton<JournalWriteDao>(
      () => JournalWriteDao(getIt<Database>()),
    )
    ..registerLazySingleton<JournalSyncDao>(
      () => JournalSyncDao(getIt<Database>()),
    )
    ..registerLazySingleton<JournalPullWriter>(
      () => JournalPullWriter(getIt<Database>()),
    )
    ..registerLazySingleton<JournalPurge>(() => JournalPurge(getIt<Database>()))
    ..registerLazySingleton<JournalRepository>(
      () => JournalRepositoryImpl(
        dao: getIt<JournalDao>(),
        writer: getIt<JournalWriteDao>(),
        currentUser: getIt<CurrentUserContext>(),
        syncEngine: getIt<SyncEngine>(),
      ),
    );

  // ── Réseau ──
  getIt
    ..registerLazySingleton<JournalSyncApi>(() => JournalSyncApi(getIt<Dio>()))
    ..registerLazySingleton<JournalPullRepository>(
      () => JournalPullRepository(
        api: getIt<JournalSyncApi>(),
        writer: getIt<JournalPullWriter>(),
        puller: getIt<PerCoursKeysetPuller>(),
        requiredAuth: requiredAuth,
      ),
    );

  // ── Retrait d'un cours réaffecté ──
  getIt<CoursEviction>().register(
    cursorPrefix: kAcademicsJournalResourcePrefix,
    evict: (coursId) => getIt<JournalPurge>().purgeCours(coursId),
  );

  // ── Remontée ──
  getIt<SyncEngine>().registerHandler(
    JournalOutboxHandler(
      api: getIt<JournalSyncApi>(),
      dao: getIt<JournalSyncDao>(),
      chapitreState: (id) => getIt<ProgrammeSyncDao>().chapitreState(id),
      chapitreRejected: (id) => getIt<ProgrammeSyncDao>().isRejected(id),
      evictCours: (coursId) => getIt<CoursEviction>().evict(coursId),
      currentUser: getIt<CurrentUserContext>(),
      extras: requiredAuth,
    ),
  );

  registerClassJournalPresentation(getIt);

  // ── Descente (après le pull cours, qui range les cours itérés) ──
  getIt<PullCoordinator>().registerHandler(
    CoursScopedPullHandler(
      resource: kAcademicsJournalResourcePrefix,
      requiredPermissions: const [Perm.academicsCourseRead],
      pull: getIt<JournalPullRepository>().syncJournal,
    ),
  );
}
