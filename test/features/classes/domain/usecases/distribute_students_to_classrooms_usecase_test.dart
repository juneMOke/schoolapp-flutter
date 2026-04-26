import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';

void main() {
  late MockClassroomRepository mockRepository;
  late DistributeStudentsToClassroomsUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = DistributeStudentsToClassroomsUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.distributeStudentsToClassrooms(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.gender,
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      academicYearId: tAcademicYearId,
      schoolLevelGroupId: tSchoolLevelGroupId,
      schoolLevelId: tSchoolLevelId,
      distributionCriterion: ClassroomDistributionCriterion.gender,
    );

    expect(result.isRight(), true);
    verify(
      () => mockRepository.distributeStudentsToClassrooms(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.gender,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NetworkFailure('Network error occurred');
    when(
      () => mockRepository.distributeStudentsToClassrooms(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.percentage,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      academicYearId: tAcademicYearId,
      schoolLevelGroupId: tSchoolLevelGroupId,
      schoolLevelId: tSchoolLevelId,
      distributionCriterion: ClassroomDistributionCriterion.percentage,
    );

    expect(result, const Left<Failure, void>(failure));
  });
}
