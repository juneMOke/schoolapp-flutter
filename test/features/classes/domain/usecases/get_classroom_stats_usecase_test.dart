import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_stats_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

final tClassroomStats = ClassroomStats(
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
  late MockClassroomRepository mockRepository;
  late GetClassroomStatsUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = GetClassroomStatsUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.getClassroomStats(),
    ).thenAnswer((_) async => Right(tClassroomStats));

    final result = await useCase();

    result.fold(
      (_) => fail('Expected Right but got Left'),
      (stats) => expect(stats, tClassroomStats),
    );
    verify(() => mockRepository.getClassroomStats()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NetworkFailure('Network error occurred');
    when(
      () => mockRepository.getClassroomStats(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left<Failure, ClassroomStats>(failure));
  });
}
