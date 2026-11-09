import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/repositories/level_correction_repository.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_status_cubit.dart';

class _InertLevelCorrectionRepository extends Mock
    implements LevelCorrectionRepository {}

/// Le module de correction de niveau, inerte, pour les tests qui montent la
/// consultation d'un dossier sans en parler : aucune correction n'a jamais
/// été posée. Rend de quoi le démonter.
Future<void> Function() registerInertLevelCorrectionModule() {
  final repository = _InertLevelCorrectionRepository();
  final changes = StreamController<Set<String>>.broadcast();
  when(() => repository.changes).thenAnswer((_) => changes.stream);
  when(
    () => repository.latestFor(any()),
  ).thenAnswer((_) async => const Right<Never, LevelCorrection?>(null));
  getIt.registerFactoryParam<LevelCorrectionStatusCubit, String, void>(
    (enrollmentId, _) => LevelCorrectionStatusCubit(
      LoadLevelCorrectionUseCase(repository),
      changes: changes.stream,
      enrollmentId: enrollmentId,
    ),
  );
  return () async {
    await changes.close();
    // Déjà parti si le test a remis GetIt à zéro avant.
    try {
      await getIt.unregister<LevelCorrectionStatusCubit>();
    } catch (_) {}
  };
}
