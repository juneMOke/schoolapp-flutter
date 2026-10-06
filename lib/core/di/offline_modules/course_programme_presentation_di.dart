import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_online_reader.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_read_api.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_children_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/chapitre_children_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/chapitre_children_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_edit_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_write_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/programme_repository_impl.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/chapitre_children_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/chapitre_cubit.dart';
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
      cours: getIt<AcademicsRefLocalDataSource>(),
      online: ProgrammeOnlineReader(
        api: ProgrammeReadApi(getIt<Dio>()),
        extras: getIt<Map<String, dynamic>>(),
      ),
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

  getIt.registerLazySingleton<ChapitreChildrenRepository>(
    () => ChapitreChildrenRepositoryImpl(
      writer: getIt<ChapitreChildrenWriteDao>(),
      blobs: getIt<ProgrammeBlobs>(),
      transfer: getIt<ProgrammeTransferApi>(),
      ids: getIt<IdGenerator>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt
    ..registerFactory(
      () => SaveChapitreEditUseCase(
        getIt<ProgrammeRepository>(),
        getIt<ChapitreChildrenRepository>(),
      ),
    )
    ..registerFactory(() => LoadSousPeriodesUseCase(getIt<CourseRepository>()));

  getIt
    ..registerFactory(
      () => AddChapitreNoteUseCase(getIt<ChapitreChildrenRepository>()),
    )
    ..registerFactory(
      () => DeleteChapitreNoteUseCase(getIt<ChapitreChildrenRepository>()),
    )
    ..registerFactory(
      () => OpenChapitreDocumentUseCase(getIt<ChapitreChildrenRepository>()),
    );

  getIt.registerFactoryParam<ChapitreCubit, String, void>(
    (chapitreId, _) => ChapitreCubit(
      chapitreId: chapitreId,
      load: getIt<LoadChapitreUseCase>(),
      save: getIt<SaveChapitreUseCase>(),
      addNote: getIt<AddChapitreNoteUseCase>(),
      deleteNote: getIt<DeleteChapitreNoteUseCase>(),
      openDocument: getIt<OpenChapitreDocumentUseCase>(),
      source: getIt<ProgrammeChangeSource>(),
      undoWindow: AppSnackBar.undoDuration,
    ),
  );

  getIt.registerFactoryParam<ProgrammeCubit, String, void>(
    (coursId, _) => ProgrammeCubit(
      coursId: coursId,
      load: getIt<LoadProgrammeUseCase>(),
      loadChapitre: getIt<LoadChapitreUseCase>(),
      loadSousPeriodes: getIt<LoadSousPeriodesUseCase>(),
      saveEdit: getIt<SaveChapitreEditUseCase>(),
      reorder: getIt<ReorderChapitresUseCase>(),
      delete: getIt<DeleteChapitreUseCase>(),
      source: getIt<ProgrammeChangeSource>(),
      newId: getIt<ProgrammeRepository>().newId,
    ),
  );
}
