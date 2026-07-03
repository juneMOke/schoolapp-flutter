import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/search_roster_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/eleve_search_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

class MockSearchRosterUseCase extends Mock implements SearchRosterUseCase {}

class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

const _tMember = ClassroomMember(
  id: 'm',
  studentId: 's',
  classroomId: 'c',
  academicYearId: 'ay',
  studentFirstName: 'J',
  studentLastName: 'D',
  studentGender: ClassroomMemberGender.female,
);

const _event = EleveSearchRequested(classroomId: 'c', academicYearId: 'ay');

void main() {
  late MockSearchRosterUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(
      const SearchRosterParams(classroomId: '', academicYearId: ''),
    );
  });

  setUp(() {
    mockUseCase = MockSearchRosterUseCase();
  });

  EleveSearchBloc buildBloc() => EleveSearchBloc(searchRoster: mockUseCase);

  blocTest<EleveSearchBloc, EleveSearchState>(
    'loading puis success (résultats non vides)',
    setUp: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right([_tMember]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(_event),
    expect: () => const [
      EleveSearchState(
        status: EleveSearchStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
      EleveSearchState(
        status: EleveSearchStatus.success,
        resultats: [_tMember],
        errorType: ResultatsErrorType.none,
      ),
    ],
    verify: (_) => verify(() => mockUseCase(any())).called(1),
  );

  blocTest<EleveSearchBloc, EleveSearchState>(
    'loading puis empty (aucun élève trouvé), pas une erreur',
    setUp: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Right(<ClassroomMember>[]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(_event),
    expect: () => const [
      EleveSearchState(
        status: EleveSearchStatus.loading,
        errorType: ResultatsErrorType.none,
      ),
      EleveSearchState(
        status: EleveSearchStatus.empty,
        errorType: ResultatsErrorType.none,
      ),
    ],
  );

  final failureCases = <Failure, ResultatsErrorType>{
    const NetworkFailure(): ResultatsErrorType.network,
    const NotFoundFailure(): ResultatsErrorType.notFound,
    const ValidationFailure(): ResultatsErrorType.validation,
    const UnauthorizedFailure(): ResultatsErrorType.forbidden,
    const InvalidCredentialsFailure(): ResultatsErrorType.invalidCredentials,
    const ServerFailure(): ResultatsErrorType.server,
    const StorageFailure(): ResultatsErrorType.storage,
    const AuthFailure(): ResultatsErrorType.auth,
    const _UnmappedFailure(): ResultatsErrorType.unknown,
  };

  for (final entry in failureCases.entries) {
    blocTest<EleveSearchBloc, EleveSearchState>(
      'mappe ${entry.key.runtimeType} -> ${entry.value}',
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(entry.key));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(_event),
      expect: () => [
        const EleveSearchState(
          status: EleveSearchStatus.loading,
          errorType: ResultatsErrorType.none,
        ),
        EleveSearchState(
          status: EleveSearchStatus.failure,
          errorType: entry.value,
        ),
      ],
    );
  }
}
