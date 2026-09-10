import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';

import '../../school_logo_fixture.dart';

class _MockSchoolRepository extends Mock implements SchoolRepository {}

void main() {
  const school = School(id: 'school-1', name: 'La Colombe', city: 'Kinshasa');

  late _MockSchoolRepository repository;
  late SchoolIdentityCubit cubit;

  void stub({School? identity, SchoolLogo? logo, Failure? logoFailure}) {
    when(repository.loadCurrentSchool).thenAnswer((_) async => Right(identity));
    when(repository.loadCurrentSchoolLogo).thenAnswer(
      (_) async => logoFailure == null
          ? Right(logo)
          : Left<Failure, SchoolLogo?>(logoFailure),
    );
  }

  setUp(() {
    repository = _MockSchoolRepository();
    cubit = SchoolIdentityCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('load() sert le nom ET le sceau', () async {
    stub(identity: school, logo: fakeSchoolLogo());

    await cubit.load();

    expect(cubit.state.school, school);
    expect(cubit.state.logo?.bytes, schoolLogoPngBytes);
  });

  test('les deux lectures ne produisent qu\'un seul état', () async {
    // Émettre le nom puis le sceau ferait clignoter les surfaces de marque à
    // chaque cycle de pull, sur un état intermédiaire qui n'a jamais existé.
    stub(identity: school, logo: fakeSchoolLogo());
    final emitted = <SchoolIdentityState>[];
    final subscription = cubit.stream.listen(emitted.add);

    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emitted, hasLength(1));
  });

  test(
    'relire les MÊMES octets ne ré-émet rien, même en nouvelle instance',
    () async {
      // Le déclencheur de relecture est chaque cycle de pull fructueux : un
      // sceau inchangé ne doit ni reconstruire la marque ni re-décoder le PNG.
      stub(identity: school, logo: fakeSchoolLogo());
      await cubit.load();

      final emitted = <SchoolIdentityState>[];
      final subscription = cubit.stream.listen(emitted.add);
      stub(
        identity: school,
        logo: SchoolLogo(
          sha256: 'sceau-1',
          bytes: Uint8List.fromList(schoolLogoPngBytes),
        ),
      );
      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emitted, isEmpty);
    },
  );

  test('un sceau remplacé est bien servi', () async {
    stub(identity: school, logo: fakeSchoolLogo());
    await cubit.load();

    stub(
      identity: school,
      logo: fakeSchoolLogo(sha256: 'sceau-2'),
    );
    await cubit.load();

    expect(cubit.state.logo?.sha256, 'sceau-2');
  });

  test('une école qui retire son sceau retombe sur ETEELO', () async {
    stub(identity: school, logo: fakeSchoolLogo());
    await cubit.load();

    stub(identity: school);
    await cubit.load();

    expect(cubit.state.school, school);
    expect(cubit.state.logo, isNull);
  });

  test('un sceau illisible ne fait pas taire le nom de l\'école', () async {
    stub(identity: school, logoFailure: const StorageFailure('base abîmée'));

    await cubit.load();

    expect(cubit.state.school, school);
    expect(cubit.state.logo, isNull);
  });

  test('clear() efface le nom ET le sceau', () async {
    stub(identity: school, logo: fakeSchoolLogo());
    await cubit.load();

    cubit.clear();

    expect(cubit.state.school, isNull);
    expect(cubit.state.logo, isNull);
  });
}
