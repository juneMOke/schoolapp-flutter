import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_day_entries_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_day_entries_bloc.dart';

class _MockUseCase extends Mock implements GetEnrollmentDayEntriesUseCase {}

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

  setUpAll(() => registerFallbackValue(DateTime(2026)));
  setUp(() => useCase = _MockUseCase());

  EnrollmentDayEntriesBloc build() =>
      EnrollmentDayEntriesBloc(getDayEntriesUseCase: useCase);

  void stub(Either<Failure, PaginatedResponse<DayEnrollmentEntry>> result) {
    when(
      () => useCase(
        day: any(named: 'day'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => result);
  }

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'une journée avec des lignes donne un état plein',
    setUp: () => stub(Right(_page(content: [_entry('a'), _entry('b')]))),
    build: build,
    act: (bloc) =>
        bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5))),
    skip: 1,
    expect: () => [
      isA<EnrollmentDayEntriesState>()
          .having((s) => s.status, 'status', EnrollmentDayEntriesStatus.success)
          .having((s) => s.entries, 'entries', hasLength(2)),
    ],
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'une journée sans ligne est un état VIDE, pas une erreur',
    // La carte ne se rendra alors pas du tout : une journée sans inscription
    // est le cas ordinaire, pas un incident.
    setUp: () => stub(Right(_page(content: const [], totalElements: 0))),
    build: build,
    act: (bloc) =>
        bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5))),
    skip: 1,
    expect: () => [
      isA<EnrollmentDayEntriesState>().having(
        (s) => s.status,
        'status',
        EnrollmentDayEntriesStatus.empty,
      ),
    ],
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'un 403 sur la liste est une erreur DE LA LISTE, avec son Failure',
    // Le cas qui justifie le second BLoC : l'agrégat a répondu 200 à cet
    // utilisateur, seule la liste lui est refusée.
    setUp: () => stub(const Left(UnauthorizedFailure('403'))),
    build: build,
    act: (bloc) =>
        bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5))),
    skip: 1,
    expect: () => [
      isA<EnrollmentDayEntriesState>()
          .having((s) => s.status, 'status', EnrollmentDayEntriesStatus.error)
          .having((s) => s.failure, 'failure', isA<UnauthorizedFailure>())
          .having((s) => s.entries, 'entries', isEmpty),
    ],
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'l\'échec emporte les lignes déjà chargées',
    setUp: () => stub(Right(_page(content: [_entry('a')]))),
    build: build,
    act: (bloc) async {
      bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5)));
      await Future<void>.delayed(Duration.zero);
      stub(const Left(NetworkFailure('coupure')));
      bloc.add(const EnrollmentDayEntriesPageChanged(1));
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, EnrollmentDayEntriesStatus.error);
      expect(
        bloc.state.entries,
        isEmpty,
        reason: 'des noms périmés sous un message d\'erreur seraient trompeurs',
      );
    },
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'la pagination AVANCE : la page affichée est celle demandée',
    // La régression d'origine : le numéro de page renvoyé par le serveur
    // était lu sous un nom de champ qu'il n'envoie pas, donc toujours 0 —
    // « suivant » redemandait sans fin la page 1, et l'indicateur restait sur
    // « 1 / N ». Le stub reproduit cet écho figé à 0.
    setUp: () => stub(
      Right(_page(content: [_entry('a')], totalPages: 4, totalElements: 30)),
    ),
    build: build,
    act: (bloc) async {
      bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(EnrollmentDayEntriesPageChanged(bloc.state.page + 1));
      await Future<void>.delayed(Duration.zero);
      bloc.add(EnrollmentDayEntriesPageChanged(bloc.state.page + 1));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.page, 2);
      verifyInOrder([
        () => useCase(day: DateTime(2026, 9, 5), page: 0),
        () => useCase(day: DateTime(2026, 9, 5), page: 1),
        () => useCase(day: DateTime(2026, 9, 5), page: 2),
      ]);
    },
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'changer de journée REMET la pagination à zéro',
    // Rester page 3 en changeant de journée afficherait une page vide d'une
    // liste qui, elle, a des lignes.
    setUp: () => stub(Right(_page(content: [_entry('a')], totalPages: 5))),
    build: build,
    act: (bloc) async {
      bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5)));
      await Future<void>.delayed(Duration.zero);
      stub(Right(_page(content: [_entry('c')], page: 2, totalPages: 5)));
      bloc.add(const EnrollmentDayEntriesPageChanged(2));
      await Future<void>.delayed(Duration.zero);
      stub(Right(_page(content: [_entry('d')], totalPages: 5)));
      bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 6)));
    },
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      expect(bloc.state.day, DateTime(2026, 9, 6));
      expect(bloc.state.page, 0);
      verify(() => useCase(day: DateTime(2026, 9, 6), page: 0)).called(1);
    },
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'changer de page sans journée ne demande rien',
    build: build,
    act: (bloc) => bloc.add(const EnrollmentDayEntriesPageChanged(2)),
    expect: () => const <EnrollmentDayEntriesState>[],
    verify: (_) => verifyNever(
      () => useCase(
        day: any(named: 'day'),
        page: any(named: 'page'),
      ),
    ),
  );

  blocTest<EnrollmentDayEntriesBloc, EnrollmentDayEntriesState>(
    'vider la liste la ramène à son état initial',
    setUp: () => stub(Right(_page(content: [_entry('a')]))),
    build: build,
    act: (bloc) async {
      bloc.add(EnrollmentDayEntriesRequested(DateTime(2026, 9, 5)));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const EnrollmentDayEntriesCleared());
    },
    wait: const Duration(milliseconds: 50),
    verify: (bloc) {
      expect(bloc.state.status, EnrollmentDayEntriesStatus.initial);
      expect(bloc.state.entries, isEmpty);
      expect(bloc.state.day, isNull);
    },
  );

  test('la taille de page est celle de la spec, sous le plafond serveur', () {
    // Le serveur refuse au-delà de 100, explicitement. Demander une grande
    // page pour éviter de paginer se heurterait à ce mur.
    expect(GetEnrollmentDayEntriesUseCase.pageSize, 8);
    expect(GetEnrollmentDayEntriesUseCase.pageSize, lessThanOrEqualTo(100));
  });
}
