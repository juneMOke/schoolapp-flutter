import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_stats_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_state.dart';

class MockGetClassroomStatsUseCase extends Mock
    implements GetClassroomStatsUseCase {}

final tStats = ClassroomStats(
  context: ClassroomStatsContext(
    academicYearId: 'year-1',
    academicYearName: '2025-2026',
    generatedAt: DateTime.utc(2026, 5, 24, 10),
  ),
  kpis: const ClassroomKpis(
    totalActive: 120,
    activeGirls: 62,
    activeBoys: 58,
    inactive: 8,
  ),
  distributionByCycle: const [
    CycleDistributionItem(
      cycleId: 'cycle-1',
      cycleCode: 'PRIMARY',
      total: 120,
      levels: [
        LevelDistributionItem(levelId: 'level-1', levelCode: 'P1', total: 120),
      ],
    ),
  ],
  detail: const ClassroomDetail(
    school: SchoolDetail(
      totalStudents: 120,
      girls: 62,
      boys: 58,
      cycles: [
        CycleDetail(
          cycleId: 'cycle-1',
          cycleCode: 'PRIMARY',
          totalStudents: 120,
          girls: 62,
          boys: 58,
          levels: [
            LevelDetail(
              levelId: 'level-1',
              levelCode: 'P1',
              totalStudents: 120,
              girls: 62,
              boys: 58,
              classrooms: [
                ClassroomItem(
                  classroomId: 'classroom-1',
                  name: 'A1',
                  totalStudents: 35,
                  girls: 18,
                  boys: 17,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ),
);

void main() {
  late MockGetClassroomStatsUseCase mockGetClassroomStatsUseCase;

  setUp(() {
    mockGetClassroomStatsUseCase = MockGetClassroomStatsUseCase();
  });

  ClassroomStatsBloc buildBloc() => ClassroomStatsBloc(
    getClassroomStatsUseCase: mockGetClassroomStatsUseCase,
  );

  group('ClassroomStatsRequested', () {
    blocTest<ClassroomStatsBloc, ClassroomStatsState>(
      'emits [loading, success] when use case succeeds',
      setUp: () {
        when(
          () => mockGetClassroomStatsUseCase(),
        ).thenAnswer((_) async => Right(tStats));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClassroomStatsRequested()),
      expect: () => [
        isA<ClassroomStatsState>()
            .having(
              (state) => state.status,
              'status',
              ClassroomStatsStatus.loading,
            )
            .having(
              (state) => state.errorType,
              'errorType',
              ClassroomStatsErrorType.none,
            ),
        isA<ClassroomStatsState>()
            .having(
              (state) => state.status,
              'status',
              ClassroomStatsStatus.success,
            )
            .having((state) => state.stats, 'stats', tStats)
            .having(
              (state) => state.errorType,
              'errorType',
              ClassroomStatsErrorType.none,
            ),
      ],
      verify: (_) {
        verify(() => mockGetClassroomStatsUseCase()).called(1);
      },
    );

    blocTest<ClassroomStatsBloc, ClassroomStatsState>(
      'emits [loading, error] with mapped network error type',
      setUp: () {
        when(() => mockGetClassroomStatsUseCase()).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClassroomStatsRequested()),
      expect: () => [
        isA<ClassroomStatsState>().having(
          (state) => state.status,
          'status',
          ClassroomStatsStatus.loading,
        ),
        isA<ClassroomStatsState>()
            .having(
              (state) => state.status,
              'status',
              ClassroomStatsStatus.error,
            )
            .having(
              (state) => state.errorType,
              'errorType',
              ClassroomStatsErrorType.network,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              'Verifiez votre connexion internet',
            ),
      ],
    );
  });
}
