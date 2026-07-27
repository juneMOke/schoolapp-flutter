import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';

const tOutcome = ClassroomSyncOutcome(
  classroomsUpserted: 2,
  membersUpserted: 0,
  notModified: false,
  syncedAt: 100,
);

void main() {
  late MockClassroomRepository mockRepository;
  late MockClassroomOfflineRepository mockOfflineRepository;
  late DistributeStudentsToClassroomsUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    mockOfflineRepository = MockClassroomOfflineRepository();
    useCase = DistributeStudentsToClassroomsUseCase(
      repository: mockRepository,
      offlineRepository: mockOfflineRepository,
    );
  });

  test(
    'delegates to repository, re-pulls the local mirror and returns Right(true) on full success',
    () async {
      when(
        () => mockRepository.distributeStudentsToClassrooms(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockOfflineRepository.syncClassrooms(
          academicYearId: tAcademicYearId,
        ),
      ).thenAnswer((_) async => const Right(tOutcome));

      final result = await useCase(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.gender,
      );

      expect(result, const Right<Failure, bool>(true));
      verify(
        () => mockRepository.distributeStudentsToClassrooms(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        ),
      ).called(1);
      verify(
        () => mockOfflineRepository.syncClassrooms(
          academicYearId: tAcademicYearId,
        ),
      ).called(1);
    },
  );

  test(
    'succès serveur mais re-pull local KO → Right(false), pas un échec',
    () async {
      when(
        () => mockRepository.distributeStudentsToClassrooms(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockOfflineRepository.syncClassrooms(
          academicYearId: tAcademicYearId,
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.gender,
      );

      expect(result, const Right<Failure, bool>(false));
    },
  );

  test('échec serveur → Left propagé, aucun re-pull local tenté', () async {
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

    expect(result, isA<Left<Failure, bool>>());
    verifyNever(
      () => mockOfflineRepository.syncClassrooms(
        academicYearId: any(named: 'academicYearId'),
      ),
    );
  });
}
