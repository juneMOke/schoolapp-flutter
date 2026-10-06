import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_sujet_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/evaluation_sujet_repository.dart';

/// Registrar du **sujet d'une évaluation** (plan front EV) : sujet, copie,
/// publications. Appelé à la fin de `registerAcademicsOffline` : il s'appuie
/// sur la base d'école et le moteur de synchro déjà enregistrés.
void registerEvaluationSujet(GetIt getIt) {
  // ── DataSources locales ──
  getIt.registerLazySingleton<EvaluationSujetLocalDataSource>(
    () => EvaluationSujetLocalDataSource(getIt()),
  );

  // ── Repositories ──
  getIt.registerLazySingleton<EvaluationSujetRepository>(
    () => EvaluationSujetRepositoryImpl(
      localDataSource: getIt<EvaluationSujetLocalDataSource>(),
    ),
  );
}
