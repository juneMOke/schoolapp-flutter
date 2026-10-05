import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<Set<String>> changes;
  late StudentPhotoRegistry registry;
  late Map<String, StudentPhotoRef> index;

  setUpAll(() {
    registerFallbackValue(const StudentPhotoRef(studentId: 'x'));
    registerFallbackValue(StudentPhotoSize.thumb);
  });

  setUp(() {
    repository = _MockRepository();
    changes = StreamController<Set<String>>.broadcast();
    index = {'a': const StudentPhotoRef(studentId: 'a', version: 's:1')};
    when(() => repository.changes).thenAnswer((_) => changes.stream);
    when(() => repository.loadIndex()).thenAnswer((_) async => Right(index));
    registry = StudentPhotoRegistry(
      loadIndex: LoadStudentPhotoIndexUseCase(repository),
      read: ReadStudentPhotoUseCase(repository),
    );
  });
  tearDown(() async {
    await registry.dispose();
    await changes.close();
  });

  test(
    'la clé suit la version de la photo, et prévient au changement',
    () async {
      final key = registry.photoKeyOf('a');
      await registry.start();
      expect(key.value, 's:1');

      var notified = 0;
      key.addListener(() => notified++);
      index = {'a': const StudentPhotoRef(studentId: 'a', version: 's:2')};
      changes.add({'a'});
      await pumpEventQueue();

      expect(key.value, 's:2');
      expect(notified, 1);
    },
  );

  test('un élève sans ligne n\'a pas de photo', () async {
    await registry.start();
    expect(registry.photoKeyOf('b').value, isNull);
    expect(await registry.photoBytesOf('b', diameter: 36), isNull);
    verifyNever(
      () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
    );
  });

  test('les octets sont lus une fois par version et par taille, puis servis '
      'en mémoire — le même tableau', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(
      () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
    ).thenAnswer(
      (_) async => Right(StudentPhotoBytes(bytes, StudentPhotoSize.thumb)),
    );
    await registry.start();

    final first = registry.photoBytesOf('a', diameter: 36);
    final concurrent = registry.photoBytesOf('a', diameter: 40);
    expect(await first, same(bytes));
    expect(await concurrent, same(bytes));
    expect(registry.peekPhotoBytes('a', diameter: 32), same(bytes));
    verify(
      () => repository.bytesOf(
        any(),
        StudentPhotoSize.thumb,
        exact: any(named: 'exact'),
      ),
    ).called(1);

    await registry.photoBytesOf('a', diameter: 52);
    verify(
      () => repository.bytesOf(
        any(),
        StudentPhotoSize.full,
        exact: any(named: 'exact'),
      ),
    ).called(1);
  });

  test(
    'une nouvelle version ne ressert pas les octets de l\'ancienne',
    () async {
      when(
        () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
      ).thenAnswer(
        (_) async => Right(
          StudentPhotoBytes(Uint8List.fromList([1]), StudentPhotoSize.thumb),
        ),
      );
      await registry.start();
      await registry.photoBytesOf('a', diameter: 36);

      index = {'a': const StudentPhotoRef(studentId: 'a', version: 's:2')};
      await registry.refresh();

      expect(registry.peekPhotoBytes('a', diameter: 36), isNull);
    },
  );

  test('une vignette servie faute de grande photo n\'est pas gardée comme '
      'la grande', () async {
    when(
      () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
    ).thenAnswer(
      (_) async => Right(
        StudentPhotoBytes(Uint8List.fromList([7]), StudentPhotoSize.thumb),
      ),
    );
    await registry.start();
    expect(await registry.photoBytesOf('a', diameter: 128), isNotNull);
    expect(registry.peekPhotoBytes('a', diameter: 128), isNull);
  });

  test('un échec de lecture rend null, sans lever', () async {
    when(
      () => repository.bytesOf(any(), any(), exact: any(named: 'exact')),
    ).thenAnswer((_) async => const Left(StorageFailure('disque')));
    await registry.start();
    expect(await registry.photoBytesOf('a', diameter: 36), isNull);
  });
}
