import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/attachments/attachment_availability.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/resource_sync_signals.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/depot/evaluation_depot_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart'
    show kAcademicsEvaluationsResourcePrefix;
import 'package:school_app_flutter/features/academics/data/repositories/offline/depot/depot_copie_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/depot_copie_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/depot/depot_copie_use_cases.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/depot/depots_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les copies déposées par les parents (portail parent, V180). Elles
/// descendent avec les évaluations (`EvaluationViewApplier`) ; ici, leur
/// lecture et l'ouverture de leurs pages.
void registerEvaluationDepots(GetIt getIt) {
  getIt.registerLazySingleton<EvaluationDepotLocalDataSource>(
    () => EvaluationDepotLocalDataSource(getIt<Database>()),
  );
  getIt.registerLazySingleton<DepotCopieRepository>(
    () => DepotCopieRepositoryImpl(
      local: getIt<EvaluationDepotLocalDataSource>(),
      fetcher: getIt<AttachmentFetcher>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt.registerFactory(
    () => LoadCopiesRenduesUseCase(
      getIt<GetNotesElevesUseCase>(),
      getIt<DepotCopieRepository>(),
    ),
  );
  getIt.registerFactory(
    () => OpenDepotFichierUseCase(getIt<DepotCopieRepository>()),
  );

  // BLoC en factory (règle n°2) : un cubit par fiche ouverte.
  getIt.registerFactory<DepotsCubit>(
    () => DepotsCubit(
      load: getIt<LoadCopiesRenduesUseCase>(),
      open: getIt<OpenDepotFichierUseCase>(),
      availability: getIt<AttachmentAvailabilityTracker>(),
      signals: ResourceSyncSignals(
        bus: getIt<PullCompletionBus>(),
        engine: getIt<SyncEngine>(),
        watched: const {kAcademicsEvaluationsResourcePrefix},
        pull: () => getIt<PullCoordinator>().pullSubset(const {
          kAcademicsEvaluationsResourcePrefix,
        }),
      ),
    ),
  );
}
