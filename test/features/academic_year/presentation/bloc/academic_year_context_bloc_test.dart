import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

class MockAcademicYearContextRepository extends Mock
    implements AcademicYearContextRepository {}

void main() {
  late MockAcademicYearContextRepository repository;

  const year = AcademicYear(id: 'ay-1', name: '2026', current: true);
  const level = SchoolLevel(
    id: 'lvl-1',
    name: '1ère Primaire',
    code: 'P1',
    displayOrder: 1,
    splitIntoClassrooms: false,
  );
  const context = AcademicYearContext(
    academicYear: year,
    schoolLevelGroups: [
      SchoolLevelGroupBundle(
        group: SchoolLevelGroup(id: 'grp-1', name: 'Primaire', code: 'PRIM'),
        levels: [level],
      ),
    ],
  );

  setUp(() {
    repository = MockAcademicYearContextRepository();
  });

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'succès : hasData=true, blocksNavigation=false',
    build: () {
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) async => const Right(context));
      return AcademicYearContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearContextRequested()),
    expect: () => [
      const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.loading,
      ),
      const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: context,
      ),
    ],
    verify: (bloc) {
      expect(bloc.state.blocksNavigation, isFalse);
      expect(bloc.state.hasBlockingFailure, isFalse);
    },
  );

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'échec sans donnée locale : hasBlockingFailure=true (ErrorView)',
    build: () {
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));
      return AcademicYearContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearContextRequested()),
    verify: (bloc) {
      expect(bloc.state.blocksNavigation, isFalse);
      expect(bloc.state.hasBlockingFailure, isTrue);
    },
  );

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'retry rejoue le chargement',
    build: () {
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) async => const Right(context));
      return AcademicYearContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearContextRetryRequested()),
    verify: (bloc) {
      expect(bloc.state.status, AcademicYearContextLoadStatus.success);
      verify(() => repository.loadCurrentContext()).called(1);
    },
  );

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'patch split : persiste via le repository ET met à jour le state en mémoire',
    build: () {
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) async => const Right(context));
      when(
        () => repository.markSchoolLevelSplit('lvl-1'),
      ).thenAnswer((_) async {});
      return AcademicYearContextBloc(repository: repository);
    },
    act: (bloc) async {
      bloc.add(const AcademicYearContextRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AcademicYearContextSchoolLevelSplitPatched('lvl-1'));
    },
    verify: (bloc) {
      verify(() => repository.markSchoolLevelSplit('lvl-1')).called(1);
      final patchedLevel =
          bloc.state.context!.schoolLevelGroups.single.levels.single;
      expect(patchedLevel.splitIntoClassrooms, isTrue);
    },
  );

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'patch split sans contexte chargé → no-op',
    build: () => AcademicYearContextBloc(repository: repository),
    act: (bloc) =>
        bloc.add(const AcademicYearContextSchoolLevelSplitPatched('lvl-1')),
    expect: () => <AcademicYearContextState>[],
    verify: (_) {
      verifyNever(() => repository.markSchoolLevelSplit(any()));
    },
  );

  group('sessionExpired (401/403 sur le pull référentiel)', () {
    blocTest<AcademicYearContextBloc, AcademicYearContextState>(
      'InvalidCredentialsFailure → sessionExpired=true (main.dart déclenchera '
      'un logout)',
      build: () {
        when(() => repository.loadCurrentContext()).thenAnswer(
          (_) async => const Left(InvalidCredentialsFailure('expired')),
        );
        return AcademicYearContextBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const AcademicYearContextRequested()),
      verify: (bloc) => expect(bloc.state.sessionExpired, isTrue),
    );

    blocTest<AcademicYearContextBloc, AcademicYearContextState>(
      'UnauthorizedFailure → sessionExpired=true',
      build: () {
        when(
          () => repository.loadCurrentContext(),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure('forbidden')));
        return AcademicYearContextBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const AcademicYearContextRequested()),
      verify: (bloc) => expect(bloc.state.sessionExpired, isTrue),
    );

    blocTest<AcademicYearContextBloc, AcademicYearContextState>(
      'NetworkFailure (hors-ligne) → sessionExpired reste false',
      build: () {
        when(
          () => repository.loadCurrentContext(),
        ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));
        return AcademicYearContextBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const AcademicYearContextRequested()),
      verify: (bloc) => expect(bloc.state.sessionExpired, isFalse),
    );

    blocTest<AcademicYearContextBloc, AcademicYearContextState>(
      'échec auth APRÈS une résolution réussie → sessionExpired reste false '
      '(pas de logout : le contexte local suffit)',
      build: () {
        var callCount = 0;
        when(() => repository.loadCurrentContext()).thenAnswer((_) async {
          callCount++;
          return callCount == 1
              ? const Right(context)
              : const Left(UnauthorizedFailure('forbidden'));
        });
        return AcademicYearContextBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const AcademicYearContextRequested());
        await Future<void>.delayed(Duration.zero);
        // Rafraîchissement au retour réseau (main.dart, transition
        // offline→online) : c'est ce chemin qui éjectait l'agent de son écran
        // sur un 401/403 isolé, alors que la session était intacte.
        bloc.add(const AcademicYearContextRetryRequested());
      },
      verify: (bloc) {
        expect(bloc.state.sessionExpired, isFalse);
        expect(bloc.state.context, isNotNull);
      },
    );

    blocTest<AcademicYearContextBloc, AcademicYearContextState>(
      'un succès qui suit un échec auth redescend sessionExpired à false',
      build: () {
        var callCount = 0;
        when(() => repository.loadCurrentContext()).thenAnswer((_) async {
          callCount++;
          return callCount == 1
              ? const Left(UnauthorizedFailure('forbidden'))
              : const Right(context);
        });
        return AcademicYearContextBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const AcademicYearContextRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AcademicYearContextRetryRequested());
      },
      verify: (bloc) {
        expect(bloc.state.sessionExpired, isFalse);
        expect(bloc.state.status, AcademicYearContextLoadStatus.success);
      },
    );
  });

  test(
    'anti-course : un reset pendant une résolution en vol invalide son '
    'résultat (pas d\'EventTransformer, événements concurrents par défaut)',
    () async {
      final completer = Completer<Either<Failure, AcademicYearContext>>();
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) => completer.future);
      final bloc = AcademicYearContextBloc(repository: repository);
      addTearDown(bloc.close);

      bloc.add(const AcademicYearContextRequested());
      await Future<void>.delayed(Duration.zero);

      // Logout pendant que la résolution ci-dessus est encore en vol.
      bloc.add(const AcademicYearContextResetRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const AcademicYearContextState.initial());

      // La résolution périmée (pré-reset) aboutit enfin : ne doit PAS
      // ressusciter un contexte après le reset (fuite inter-école évitée).
      completer.complete(const Right(context));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, const AcademicYearContextState.initial());
    },
  );

  blocTest<AcademicYearContextBloc, AcademicYearContextState>(
    'reset (logout) : remet le state à initial',
    build: () {
      when(
        () => repository.loadCurrentContext(),
      ).thenAnswer((_) async => const Right(context));
      return AcademicYearContextBloc(repository: repository);
    },
    act: (bloc) async {
      bloc.add(const AcademicYearContextRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AcademicYearContextResetRequested());
    },
    verify: (bloc) {
      expect(bloc.state, const AcademicYearContextState.initial());
    },
  );
}
