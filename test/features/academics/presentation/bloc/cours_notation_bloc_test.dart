import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_cours_notation_detail_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_state.dart';

class MockGetCoursNotationDetailUseCase extends Mock
    implements GetCoursNotationDetailUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

const tCoursId = 'cours-1';

const tDetail = CoursNotationDetail(
  coursId: tCoursId,
  classroomId: 'class-1',
  brancheNom: 'Mathématiques',
  effectif: 30,
  periodes: [],
);

void main() {
  late MockGetCoursNotationDetailUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetCoursNotationDetailUseCase();
  });

  CoursNotationBloc buildBloc() =>
      CoursNotationBloc(getCoursNotationDetailUseCase: mockUseCase);

  group('CoursNotationRequested', () {
    blocTest<CoursNotationBloc, CoursNotationState>(
      'emits loading then success with fetched detail',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tDetail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.success,
          detail: tDetail,
          errorType: CoursNotationErrorType.none,
        ),
      ],
      verify: (_) {
        verify(() => mockUseCase(tCoursId)).called(1);
      },
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps NotFoundFailure to notFound error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.notFound,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps UnauthorizedFailure (403) to forbidden error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.forbidden,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps NetworkFailure to network error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.network,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps InvalidCredentialsFailure (401) to invalidCredentials error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.invalidCredentials,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps ValidationFailure to validation error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(ValidationFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.validation,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps ServerFailure (5xx) to server error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.server,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps StorageFailure to storage error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(StorageFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.storage,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps AuthFailure to auth error type',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(AuthFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.auth,
        ),
      ],
    );

    blocTest<CoursNotationBloc, CoursNotationState>(
      'maps an unmapped Failure to unknown error type (branche par défaut)',
      setUp: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Left(_UnmappedFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const CoursNotationRequested(coursId: tCoursId)),
      expect: () => const [
        CoursNotationState(
          status: CoursNotationStatus.loading,
          errorType: CoursNotationErrorType.none,
        ),
        CoursNotationState(
          status: CoursNotationStatus.failure,
          errorType: CoursNotationErrorType.unknown,
        ),
      ],
    );
  });
}
