import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/domain/repositories/academic_year_context_repository.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_previous_context_bloc.dart';

class MockAcademicYearContextRepository extends Mock
    implements AcademicYearContextRepository {}

void main() {
  late MockAcademicYearContextRepository repository;

  const previousYearContext = AcademicYearContext(
    academicYear: AcademicYear(id: 'ay-prev', name: '2025', current: false),
    schoolLevelGroups: [],
  );

  setUp(() {
    repository = MockAcademicYearContextRepository();
  });

  blocTest<AcademicYearPreviousContextBloc, AcademicYearPreviousContextState>(
    'pas d\'année antérieure → succès résolu avec context=null (pas un échec)',
    build: () {
      when(
        () => repository.loadPreviousContext(),
      ).thenAnswer((_) async => const Right(null));
      return AcademicYearPreviousContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearPreviousContextRequested()),
    expect: () => [
      const AcademicYearPreviousContextState(
        status: AcademicYearPreviousContextLoadStatus.loading,
      ),
      const AcademicYearPreviousContextState(
        status: AcademicYearPreviousContextLoadStatus.success,
      ),
    ],
    verify: (bloc) {
      expect(bloc.state.isResolved, isTrue);
      expect(bloc.state.context, isNull);
    },
  );

  blocTest<AcademicYearPreviousContextBloc, AcademicYearPreviousContextState>(
    'année antérieure connue → succès avec context peuplé',
    build: () {
      when(
        () => repository.loadPreviousContext(),
      ).thenAnswer((_) async => const Right(previousYearContext));
      return AcademicYearPreviousContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearPreviousContextRequested()),
    verify: (bloc) {
      expect(bloc.state.context, previousYearContext);
    },
  );

  blocTest<AcademicYearPreviousContextBloc, AcademicYearPreviousContextState>(
    'échec repository → status failure',
    build: () {
      when(
        () => repository.loadPreviousContext(),
      ).thenAnswer((_) async => const Left(ServerFailure('boom')));
      return AcademicYearPreviousContextBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const AcademicYearPreviousContextRequested()),
    verify: (bloc) {
      expect(bloc.state.isResolved, isFalse);
      expect(bloc.state.status, AcademicYearPreviousContextLoadStatus.failure);
    },
  );
}
