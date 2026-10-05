import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';
import 'package:school_app_flutter/features/course_programme/domain/usecases/programme_use_cases.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_change_source.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_cubit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/bloc/programme_state.dart';

class _MockLoad extends Mock implements LoadProgrammeUseCase {}

class _MockReorder extends Mock implements ReorderChapitresUseCase {}

class _MockDelete extends Mock implements DeleteChapitreUseCase {}

Programme _programme(List<String> ids) => Programme(
  coursId: 'c-1',
  chapitres: [
    for (final id in ids)
      ProgrammeChapitre(
        chapitre: Chapitre(id: id, coursId: 'c-1', ordre: 0, titre: id),
      ),
  ],
);

List<String> _ids(ProgrammeState state) => [
  for (final row in state.programme!.chapitres) row.chapitre.id,
];

void main() {
  late _MockLoad load;
  late _MockReorder reorder;
  late _MockDelete delete;

  ProgrammeCubit build() => ProgrammeCubit(
    coursId: 'c-1',
    load: load,
    reorder: reorder,
    delete: delete,
    source: const ProgrammeChangeSource(),
  );

  setUp(() {
    load = _MockLoad();
    reorder = _MockReorder();
    delete = _MockDelete();
    when(
      () => load('c-1'),
    ).thenAnswer((_) async => Right(_programme(['a', 'b'])));
  });

  blocTest<ProgrammeCubit, ProgrammeState>(
    'charge le programme',
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ProgrammeStatus.ready);
      expect(_ids(cubit.state), ['a', 'b']);
    },
  );

  blocTest<ProgrammeCubit, ProgrammeState>(
    'un échec de relecture ne remplace pas une liste affichée',
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => load('c-1'),
      ).thenAnswer((_) async => const Left(StorageFailure()));
      await cubit.refresh();
    },
    verify: (cubit) => expect(cubit.state.status, ProgrammeStatus.ready),
  );

  blocTest<ProgrammeCubit, ProgrammeState>(
    'descendre un chapitre envoie la liste complète dans le nouvel ordre',
    build: build,
    act: (cubit) async {
      when(
        () => reorder('c-1', ['b', 'a']),
      ).thenAnswer((_) async => const Right(unit));
      await cubit.load();
      await cubit.move('a', 1);
    },
    verify: (_) => verify(() => reorder('c-1', ['b', 'a'])).called(1),
  );

  blocTest<ProgrammeCubit, ProgrammeState>(
    'une écriture locale en échec le dit',
    build: build,
    act: (cubit) async {
      when(
        () => reorder(any(), any()),
      ).thenAnswer((_) async => const Left(StorageFailure()));
      await cubit.load();
      await cubit.move('a', 1);
    },
    verify: (cubit) =>
        expect(cubit.state.feedback?.kind, ProgrammeFeedbackKind.writeFailed),
  );

  blocTest<ProgrammeCubit, ProgrammeState>(
    'supprimer annonce « Chapitre supprimé » et relit',
    build: build,
    act: (cubit) async {
      when(() => delete('a')).thenAnswer((_) async => const Right(unit));
      await cubit.load();
      await cubit.delete('a');
    },
    verify: (cubit) {
      expect(cubit.state.feedback?.kind, ProgrammeFeedbackKind.chapitreDeleted);
      verify(() => load('c-1')).called(2);
    },
  );
}
