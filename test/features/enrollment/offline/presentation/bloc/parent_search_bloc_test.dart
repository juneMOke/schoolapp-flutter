import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_state.dart';

class MockSearchParentsUseCase extends Mock implements SearchParentsUseCase {}

const tParent = LocalParent(
  id: 'p1',
  firstName: 'Sarah',
  lastName: 'Moke',
  phoneNumber: '+243111',
);

void main() {
  late MockSearchParentsUseCase search;

  setUp(() {
    search = MockSearchParentsUseCase();
  });

  ParentSearchBloc buildBloc() => ParentSearchBloc(search: search);

  test('état initial : ParentSearchInitial', () {
    expect(buildBloc().state, const ParentSearchInitial());
  });

  blocTest<ParentSearchBloc, ParentSearchState>(
    'résultats non vides → [loading, loaded]',
    setUp: () {
      when(
        () => search(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => const Right([tParent]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ParentSearchRequested(lastName: 'Moke')),
    expect: () => [
      const ParentSearchLoading(),
      const ParentSearchLoaded([tParent]),
    ],
  );

  blocTest<ParentSearchBloc, ParentSearchState>(
    'résultats vides → [loading, empty]',
    setUp: () {
      when(
        () => search(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => const Right([]));
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const ParentSearchRequested(phoneNumber: '+243000')),
    expect: () => [const ParentSearchLoading(), const ParentSearchEmpty()],
  );

  blocTest<ParentSearchBloc, ParentSearchState>(
    'échec → [loading, error]',
    setUp: () {
      when(
        () => search(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left(StorageFailure('Erreur d\'accès à la base locale.')),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ParentSearchRequested(lastName: 'Moke')),
    expect: () => [
      const ParentSearchLoading(),
      const ParentSearchError('Erreur d\'accès à la base locale.'),
    ],
  );
}
