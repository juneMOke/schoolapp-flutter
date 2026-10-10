import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/repositories/journal_repository.dart';
import 'package:school_app_flutter/features/class_journal/domain/usecases/load_journal_day_use_case.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_change_source.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/course_programme/domain/repositories/programme_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Le journal de classe, côté écrans : cas d'usage, source de signaux, cubits
/// (en fabrique — jamais singleton). Appelé par [registerClassJournal].
void registerClassJournalPresentation(GetIt getIt) {
  getIt
    ..registerLazySingleton<JournalChangeSource>(
      () => JournalChangeSource(
        bus: getIt<PullCompletionBus>(),
        engine: getIt<SyncEngine>(),
        pull: () async {
          await getIt<PullCoordinator>().pullSubset(
            JournalChangeSource.watchedResources,
          );
        },
      ),
    )
    ..registerFactory(
      () => LoadJournalDayUseCase(
        schedule: getIt<ScheduleRepository>(),
        courses: getIt<CourseRepository>(),
        journal: getIt<JournalRepository>(),
        programme: getIt<ProgrammeRepository>(),
      ),
    )
    ..registerFactory(
      () => JournalDayCubit(
        load: getIt<LoadJournalDayUseCase>(),
        source: getIt<JournalChangeSource>(),
      ),
    );
}
