import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_change_source.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';

/// Le programme de cours, côté écrans : dépôts, cas d'usage, cubits (en
/// fabrique — jamais singleton). Appelé par [registerCourseProgramme], après
/// les DAO et la synchro.
void registerCourseProgrammePresentation(GetIt getIt) {
  getIt.registerLazySingleton<ProgrammeRepository>(
    () => ProgrammeRepositoryImpl(
      dao: getIt<ChapitreDao>(),
      writer: getIt<ChapitreWriteDao>(),
      evaluations: getIt<AcademicsLocalDataSource>(),
      ids: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton<ProgrammeChangeSource>(
    () => ProgrammeChangeSource(
      bus: getIt<PullCompletionBus>(),
      engine: getIt<SyncEngine>(),
    ),
  );

  getIt
    ..registerFactory(() => LoadProgrammeUseCase(getIt<ProgrammeRepository>()))
    ..registerFactory(() => LoadChapitreUseCase(getIt<ProgrammeRepository>()))
    ..registerFactory(() => SaveChapitreUseCase(getIt<ProgrammeRepository>()))
    ..registerFactory(() => DeleteChapitreUseCase(getIt<ProgrammeRepository>()))
    ..registerFactory(
      () => ReorderChapitresUseCase(getIt<ProgrammeRepository>()),
    );

  getIt.registerFactoryParam<ProgrammeCubit, String, void>(
    (coursId, _) => ProgrammeCubit(
      coursId: coursId,
      load: getIt<LoadProgrammeUseCase>(),
      reorder: getIt<ReorderChapitresUseCase>(),
      delete: getIt<DeleteChapitreUseCase>(),
      source: getIt<ProgrammeChangeSource>(),
    ),
  );
}
