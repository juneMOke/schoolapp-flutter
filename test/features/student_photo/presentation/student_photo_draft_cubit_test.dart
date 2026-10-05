import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

void main() {
  late _MockRepository repository;
  late StudentPhotoDraftCubit cubit;
  final photo = Uint8List.fromList([1, 2, 3]);
  final at = DateTime.utc(2026, 10, 5);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime(2026));
  });

  void saveAnswers(Either<Failure, Unit> result) => when(
    () => repository.savePhoto(
      studentId: any(named: 'studentId'),
      jpeg: any(named: 'jpeg'),
      takenAt: any(named: 'takenAt'),
    ),
  ).thenAnswer((_) async => result);

  setUp(() {
    repository = _MockRepository();
    saveAnswers(const Right(unit));
    cubit = StudentPhotoDraftCubit(save: SaveStudentPhotoUseCase(repository));
  });
  tearDown(() => cubit.close());

  test('avant l\'étape 1 : la photo reste en mémoire, rien ne part', () async {
    await cubit.keep(photo, at);
    expect(cubit.state.photo, photo);
    verifyNever(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    );
  });

  test('l\'étape 1 enregistrée : la photo part, datée de sa prise', () async {
    await cubit.keep(photo, at);
    await cubit.studentSaved('s-1');
    verify(
      () => repository.savePhoto(studentId: 's-1', jpeg: photo, takenAt: at),
    ).called(1);
    expect(cubit.state.photo, isNull);
    expect(cubit.state.studentSaved, isTrue);
  });

  test('après l\'étape 1, une photo prise part aussitôt', () async {
    await cubit.studentSaved('s-1');
    await cubit.keep(photo, at);
    verify(
      () => repository.savePhoto(studentId: 's-1', jpeg: photo, takenAt: at),
    ).called(1);
  });

  test('un enregistrement raté garde la photo pour la fois suivante', () async {
    saveAnswers(const Left(StorageFailure('disque')));
    await cubit.keep(photo, at);
    await cubit.studentSaved('s-1');
    expect(cubit.state.photo, photo);
  });

  test('retirer la photo gardée : plus rien ne part', () async {
    await cubit.keep(photo, at);
    cubit.discard();
    await cubit.studentSaved('s-1');
    verifyNever(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    );
  });
}
