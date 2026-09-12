import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_entries_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_bloc.dart';

class _MockUseCase extends Mock implements GetEnrollmentEntriesUseCase {}

typedef _Result = Either<Failure, PaginatedResponse<DayEnrollmentEntry>>;

DayEnrollmentEntry _entry(String id) => DayEnrollmentEntry(
  enrollmentId: id,
  studentId: 's-$id',
  firstName: 'Amina',
  lastName: 'Kabila',
  surname: '',
  gender: Gender.female,
  schoolLevelId: 'lvl',
  schoolLevel: '6e année',
  cycle: 'PRIMARY',
  formerStudent: false,
  enrollmentDate: DateTime(2026, 9, 5),
  createdAt: DateTime(2026, 9, 5, 9, 30),
  recordedBy: 'M. Ilunga',
);

PaginatedResponse<DayEnrollmentEntry> _page({
  required List<DayEnrollmentEntry> content,
  int page = 0,
  int totalPages = 1,
  int totalElements = 1,
}) => PaginatedResponse<DayEnrollmentEntry>(
  content: content,
  page: page,
  size: 8,
  totalPages: totalPages,
  totalElements: totalElements,
);

void main() {
  late _MockUseCase useCase;

  setUpAll(() => registerFallbackValue(const EnrollmentStatsWindow.year()));
  setUp(() => useCase = _MockUseCase());

  EnrollmentEntriesBloc build() =>
      EnrollmentEntriesBloc(getEntriesUseCase: useCase);

  void stub(_Result result) {
    when(
      () => useCase(
        window: any(named: 'window'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => result);
  }

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'une semaine se liste aussi — la liste n\'est plus réservée au jour',
    setUp: () => stub(Right(_page(content: [_entry('a'), _entry('b')]))),
    build: build,
    act: (bloc) => bloc.add(
      const EnrollmentEntriesRequested(EnrollmentStatsWindow.week()),
    ),
    skip: 1,
    expect: () => [
      isA<EnrollmentEntriesState>()
          .having((s) => s.status, 'status', EnrollmentEntriesStatus.success)
          .having((s) => s.entries, 'entries', hasLength(2))
          .having(
            (s) => s.window,
            'window',
            const EnrollmentStatsWindow.week(),
          ),
    ],
    verify: (_) => verify(
      () => useCase(window: const EnrollmentStatsWindow.week(), page: 0),
    ).called(1),
  );

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'une fenêtre sans ligne est un état VIDE, pas une erreur',
    // La carte ne se rendra alors pas du tout : une fenêtre sans inscription
    // terminée est un cas ordinaire, pas un incident.
    setUp: () => stub(Right(_page(content: const [], totalElements: 0))),
    build: build,
    act: (bloc) => bloc.add(
      const EnrollmentEntriesRequested(EnrollmentStatsWindow.month()),
    ),
    skip: 1,
    expect: () => [
      isA<EnrollmentEntriesState>().having(
        (s) => s.status,
        'status',
        EnrollmentEntriesStatus.empty,
      ),
    ],
  );

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'un 403 sur la liste est une erreur DE LA LISTE, avec son Failure',
    // Le cas qui justifie le second BLoC : l'agrégat a répondu 200 à cet
    // utilisateur, seule la liste lui est refusée.
    setUp: () => stub(const Left(UnauthorizedFailure('403'))),
    build: build,
    act: (bloc) => bloc.add(
      const EnrollmentEntriesRequested(EnrollmentStatsWindow.year()),
    ),
    skip: 1,
    expect: () => [
      isA<EnrollmentEntriesState>()
          .having((s) => s.status, 'status', EnrollmentEntriesStatus.error)
          .having((s) => s.failure, 'failure', isA<UnauthorizedFailure>())
          .having((s) => s.entries, 'entries', isEmpty),
    ],
  );

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'l\'échec emporte les lignes déjà chargées',
    setUp: () => stub(Right(_page(content: [_entry('a')], totalPages: 3))),
    build: build,
    act: (bloc) async {
      bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.year()));
      await Future<void>.delayed(Duration.zero);
      stub(const Left(NetworkFailure('coupure')));
      bloc.add(const EnrollmentEntriesPageChanged(1));
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, EnrollmentEntriesStatus.error);
      expect(
        bloc.state.entries,
        isEmpty,
        reason: 'des noms périmés sous un message d\'erreur seraient trompeurs',
      );
    },
  );

  group('la pagination avance', () {
    blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
      'la page affichée est celle DEMANDÉE, même si la réponse annonce 0',
      // La régression d'origine : le numéro de page renvoyé par le serveur
      // était lu sous un nom de champ qu'il n'envoie pas, donc toujours 0 —
      // « suivant » redemandait sans fin la page 1, et l'indicateur restait
      // sur « 1 / N ». Le stub reproduit cet écho figé.
      setUp: () => stub(
        Right(_page(content: [_entry('a')], totalPages: 4, totalElements: 30)),
      ),
      build: build,
      act: (bloc) async {
        bloc.add(
          const EnrollmentEntriesRequested(EnrollmentStatsWindow.year()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(EnrollmentEntriesPageChanged(bloc.state.page + 1));
        await Future<void>.delayed(Duration.zero);
        bloc.add(EnrollmentEntriesPageChanged(bloc.state.page + 1));
      },
      wait: const Duration(milliseconds: 80),
      verify: (bloc) {
        expect(bloc.state.page, 2);
        expect(bloc.state.status, EnrollmentEntriesStatus.success);
        verifyInOrder([
          () => useCase(window: const EnrollmentStatsWindow.year(), page: 0),
          () => useCase(window: const EnrollmentStatsWindow.year(), page: 1),
          () => useCase(window: const EnrollmentStatsWindow.year(), page: 2),
        ]);
      },
    );

    blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
      'une page hors bornes ne part pas',
      // Une page négative partirait en 400 ; une page au-delà de la dernière
      // afficherait une table vide d'une fenêtre qui a des lignes.
      setUp: () => stub(
        Right(_page(content: [_entry('a')], totalPages: 2, totalElements: 9)),
      ),
      build: build,
      act: (bloc) async {
        bloc.add(
          const EnrollmentEntriesRequested(EnrollmentStatsWindow.week()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EnrollmentEntriesPageChanged(-1));
        bloc.add(const EnrollmentEntriesPageChanged(2));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.page, 0);
        verify(
          () => useCase(
            window: any(named: 'window'),
            page: any(named: 'page'),
          ),
        ).called(1);
      },
    );
  });

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'changer de fenêtre REMET la pagination à zéro',
    // Rester page 3 en passant de l'année à la semaine afficherait une page
    // vide d'une liste qui, elle, a des lignes.
    setUp: () => stub(Right(_page(content: [_entry('a')], totalPages: 5))),
    build: build,
    act: (bloc) async {
      bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.year()));
      await Future<void>.delayed(Duration.zero);
      stub(Right(_page(content: [_entry('c')], totalPages: 5)));
      bloc.add(const EnrollmentEntriesPageChanged(2));
      await Future<void>.delayed(Duration.zero);
      stub(Right(_page(content: [_entry('d')], totalPages: 5)));
      bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.week()));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.window, const EnrollmentStatsWindow.week());
      expect(bloc.state.page, 0);
      verify(
        () => useCase(window: const EnrollmentStatsWindow.week(), page: 0),
      ).called(1);
    },
  );

  test('une réponse PÉRIMÉE ne s\'affiche jamais', () async {
    // L'année est lente, la semaine rapide : l'année revient en dernier. Ses
    // noms sous le titre « cette semaine » seraient pires qu'une table vide.
    final slowYear = Completer<_Result>();
    when(
      () => useCase(window: const EnrollmentStatsWindow.year(), page: 0),
    ).thenAnswer((_) => slowYear.future);
    when(
      () => useCase(window: const EnrollmentStatsWindow.week(), page: 0),
    ).thenAnswer((_) async => Right(_page(content: [_entry('semaine')])));

    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.year()));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.week()));
    await Future<void>.delayed(Duration.zero);
    slowYear.complete(Right(_page(content: [_entry('annee')])));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.window, const EnrollmentStatsWindow.week());
    expect(bloc.state.entries.single.enrollmentId, 'semaine');
  });

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'changer de page sans fenêtre ne demande rien',
    build: build,
    act: (bloc) => bloc.add(const EnrollmentEntriesPageChanged(2)),
    expect: () => const <EnrollmentEntriesState>[],
    verify: (_) => verifyNever(
      () => useCase(
        window: any(named: 'window'),
        page: any(named: 'page'),
      ),
    ),
  );

  blocTest<EnrollmentEntriesBloc, EnrollmentEntriesState>(
    'vider la liste la ramène à son état initial',
    setUp: () => stub(Right(_page(content: [_entry('a')]))),
    build: build,
    act: (bloc) async {
      bloc.add(const EnrollmentEntriesRequested(EnrollmentStatsWindow.week()));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const EnrollmentEntriesCleared());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, EnrollmentEntriesStatus.initial);
      expect(bloc.state.entries, isEmpty);
      expect(bloc.state.window, isNull);
    },
  );

  test('la taille de page est celle de la spec, sous le plafond serveur', () {
    // Le serveur refuse au-delà de 100, explicitement — et elle ne grandit
    // pas avec la fenêtre.
    expect(GetEnrollmentEntriesUseCase.pageSize, 8);
    expect(GetEnrollmentEntriesUseCase.pageSize, lessThanOrEqualTo(100));
  });
}
