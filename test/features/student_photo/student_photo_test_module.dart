import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_edit_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';

class _InertPhotoRepository extends Mock implements StudentPhotoRepository {}

/// Le module photo, inerte, pour les tests qui montent une page portant une
/// entrée photo (étape Identité, en-tête du parcours) sans parler de photo :
/// aucun élève n'a de photo, rien ne part. Rend de quoi le démonter.
Future<void> Function() registerInertStudentPhotoModule() {
  final repository = _InertPhotoRepository();
  final changes = StreamController<Set<String>>.broadcast();
  when(() => repository.changes).thenAnswer((_) => changes.stream);
  when(
    () => repository.loadIndex(),
  ).thenAnswer((_) async => const Right(<String, StudentPhotoRef>{}));
  final registry = StudentPhotoRegistry(
    loadIndex: LoadStudentPhotoIndexUseCase(repository),
    read: ReadStudentPhotoUseCase(repository),
  );
  getIt
    ..registerSingleton<StudentPhotoRegistry>(registry)
    ..registerFactory<StudentPhotoEditCubit>(
      () =>
          StudentPhotoEditCubit(remove: RemoveStudentPhotoUseCase(repository)),
    )
    ..registerFactory<StudentPhotoDraftCubit>(
      () => StudentPhotoDraftCubit(save: SaveStudentPhotoUseCase(repository)),
    );
  return () async {
    await registry.dispose();
    await changes.close();
    for (final unregister in [
      () => getIt.unregister<StudentPhotoRegistry>(),
      () => getIt.unregister<StudentPhotoEditCubit>(),
      () => getIt.unregister<StudentPhotoDraftCubit>(),
    ]) {
      // Déjà parti si le test a remis GetIt à zéro avant.
      try {
        await unregister();
      } catch (_) {}
    }
  };
}
