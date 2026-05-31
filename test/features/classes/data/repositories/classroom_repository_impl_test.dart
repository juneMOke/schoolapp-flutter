import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/data/datasources/classroom_remote_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_with_members_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_member_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_model.dart';
import 'package:school_app_flutter/features/classes/data/models/distribution_request_model.dart';
import 'package:school_app_flutter/features/classes/data/models/level_distribution_overview_model.dart';
import 'package:school_app_flutter/features/classes/data/models/reassign_classroom_member_request_model.dart';
import 'package:school_app_flutter/features/classes/data/repositories/classroom_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/data/models/student_summary_model.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class MockClassroomRemoteDataSource extends Mock
    implements ClassroomRemoteDataSource {}

class FakeDistributionRequestModel extends Fake
    implements DistributionRequestModel {}

class FakeReassignClassroomMemberRequestModel extends Fake
    implements ReassignClassroomMemberRequestModel {}

const tRequiredAuth = <String, dynamic>{'requiresAuth': true};
const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';
const tClassroomId = 'classroom-1';
const tClassroomMemberId = 'member-1';
const tTargetClassroomId = 'classroom-2';

final tClassroomStatsResponseModel = ClassroomStatsResponseModel(
  context: ClassroomStatsContextModel(
    academicYearId: tAcademicYearId,
    academicYearName: '2025-2026',
    generatedAt: DateTime.utc(2026, 5, 24, 10),
  ),
  kpis: const ClassroomKpisModel(
    totalActive: 120,
    activeGirls: 62,
    activeBoys: 58,
    inactive: 8,
  ),
  distributionByCycle: const [
    CycleDistributionItemModel(
      cycleId: 'cycle-1',
      cycleCode: 'PRIMARY',
      total: 120,
      levels: [
        LevelDistributionItemModel(
          levelId: tSchoolLevelId,
          levelCode: 'P1',
          total: 120,
        ),
      ],
    ),
  ],
  detail: const ClassroomDetailModel(
    school: SchoolDetailModel(
      totalStudents: 120,
      girls: 62,
      boys: 58,
      cycles: [
        CycleDetailModel(
          cycleId: 'cycle-1',
          cycleCode: 'PRIMARY',
          totalStudents: 120,
          girls: 62,
          boys: 58,
          levels: [
            LevelDetailModel(
              levelId: tSchoolLevelId,
              levelCode: 'P1',
              totalStudents: 120,
              girls: 62,
              boys: 58,
              classrooms: [
                ClassroomItemModel(
                  classroomId: tClassroomId,
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

final tClassroomStats = ClassroomStats(
  context: ClassroomStatsContext(
    academicYearId: tAcademicYearId,
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
        LevelDistributionItem(
          levelId: tSchoolLevelId,
          levelCode: 'P1',
          total: 120,
        ),
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
              levelId: tSchoolLevelId,
              levelCode: 'P1',
              totalStudents: 120,
              girls: 62,
              boys: 58,
              classrooms: [
                ClassroomItem(
                  classroomId: tClassroomId,
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

const tClassroomMemberModel = ClassroomMemberModel(
  id: 'member-1',
  studentId: 'student-1',
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: 'MALE',
);

const tClassroomMember = ClassroomMember(
  id: 'member-1',
  studentId: 'student-1',
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: ClassroomMemberGender.male,
);

const tClassroomModel = ClassroomModel(
  id: 'classroom-1',
  schoolLevelGroupId: tSchoolLevelGroupId,
  schoolLevelId: tSchoolLevelId,
  academicYearId: tAcademicYearId,
  name: 'A1',
  capacity: 40,
  teacherId: 'teacher-1',
  teacherFirstName: 'Alice',
  teacherLastName: 'Doe',
  teacherMiddleName: null,
  totalCount: 32,
  femaleCount: 16,
  maleCount: 16,
);

const tClassroom = Classroom(
  id: 'classroom-1',
  schoolLevelGroupId: tSchoolLevelGroupId,
  schoolLevelId: tSchoolLevelId,
  academicYearId: tAcademicYearId,
  name: 'A1',
  capacity: 40,
  teacherId: 'teacher-1',
  teacherFirstName: 'Alice',
  teacherLastName: 'Doe',
  teacherMiddleName: null,
  totalCount: 32,
  femaleCount: 16,
  maleCount: 16,
);

const tStudentSummaryModel = StudentSummaryModel(
  id: 'student-1',
  firstName: 'John',
  lastName: 'Doe',
  surname: 'K',
  dateOfBirth: '2012-01-01',
  gender: 'MALE',
);

final tEnrollmentSummaryModel = EnrollmentSummaryModel(
  enrollmentId: 'enrollment-1',
  enrollmentCode: 'ENR-1',
  status: 'COMPLETED',
  student: tStudentSummaryModel,
);

const tClassroomWithMembersModel = ClassroomWithMembersModel(
  classroom: tClassroomModel,
  members: [tClassroomMemberModel],
);

final tLevelDistributionOverviewModel = LevelDistributionOverviewModel(
  unassignedEnrollments: <EnrollmentSummaryModel>[tEnrollmentSummaryModel],
  classrooms: const <ClassroomWithMembersModel>[tClassroomWithMembersModel],
);

const tStudentSummary = StudentSummary(
  id: 'student-1',
  firstName: 'John',
  lastName: 'Doe',
  surname: 'K',
  dateOfBirth: '2012-01-01',
  gender: Gender.male,
);

const tEnrollmentSummary = EnrollmentSummary(
  enrollmentId: 'enrollment-1',
  enrollmentCode: 'ENR-1',
  status: 'COMPLETED',
  student: tStudentSummary,
);

const tClassroomWithMembers = ClassroomWithMembers(
  classroom: tClassroom,
  members: [tClassroomMember],
);

const tLevelDistributionOverview = LevelDistributionOverview(
  unassignedEnrollments: <EnrollmentSummary>[tEnrollmentSummary],
  classrooms: <ClassroomWithMembers>[tClassroomWithMembers],
);

void main() {
  late MockClassroomRemoteDataSource mockRemoteDataSource;
  late ClassroomRepositoryImpl repository;

  setUp(() {
    registerFallbackValue(FakeDistributionRequestModel());
    registerFallbackValue(FakeReassignClassroomMemberRequestModel());
    mockRemoteDataSource = MockClassroomRemoteDataSource();
    repository = ClassroomRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      requiredAuth: tRequiredAuth,
    );
  });

  group('getClassroomsByLevelAndAcademicYear', () {
    test('returns Right(List<Classroom>) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenAnswer((_) async => const [tClassroomModel]);

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (classrooms) => expect(classrooms, const [tClassroom]),
      );
      verify(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = NotFoundFailure('Resource not found');
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(result, const Left<Failure, List<Classroom>>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
            tRequiredAuth,
            tSchoolLevelGroupId,
            tSchoolLevelId,
            tAcademicYearId,
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getClassroomsByLevelAndAcademicYear(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        );

        expect(
          result,
          const Left<Failure, List<Classroom>>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );

    test('returns Left(ServerFailure) when payload is invalid', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(const FormatException('Invalid payload'));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(
        result,
        const Left<Failure, List<Classroom>>(
          ServerFailure('Invalid classroom payload'),
        ),
      );
    });

    test('returns Left(ServerFailure) on unknown exception', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(
        result,
        const Left<Failure, List<Classroom>>(
          ServerFailure('Unexpected error occurred'),
        ),
      );
    });
  });

  group('getClassroomMembers', () {
    test(
      'returns Right(List<ClassroomMember>) when datasource succeeds',
      () async {
        when(
          () => mockRemoteDataSource.listClassroomMembers(
            tRequiredAuth,
            tClassroomId,
            tAcademicYearId,
          ),
        ).thenAnswer((_) async => const [tClassroomMemberModel]);

        final result = await repository.getClassroomMembers(
          classroomId: tClassroomId,
          academicYearId: tAcademicYearId,
        );

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (members) => expect(members, const [tClassroomMember]),
        );
      },
    );

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = NotFoundFailure('Resource not found');
      when(
        () => mockRemoteDataSource.listClassroomMembers(
          tRequiredAuth,
          tClassroomId,
          tAcademicYearId,
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getClassroomMembers(
        classroomId: tClassroomId,
        academicYearId: tAcademicYearId,
      );

      expect(result, const Left<Failure, List<ClassroomMember>>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.listClassroomMembers(
            tRequiredAuth,
            tClassroomId,
            tAcademicYearId,
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getClassroomMembers(
          classroomId: tClassroomId,
          academicYearId: tAcademicYearId,
        );

        expect(
          result,
          const Left<Failure, List<ClassroomMember>>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );

    test('returns Left(ServerFailure) when payload is invalid', () async {
      when(
        () => mockRemoteDataSource.listClassroomMembers(
          tRequiredAuth,
          tClassroomId,
          tAcademicYearId,
        ),
      ).thenThrow(const FormatException('Invalid payload'));

      final result = await repository.getClassroomMembers(
        classroomId: tClassroomId,
        academicYearId: tAcademicYearId,
      );

      expect(
        result,
        const Left<Failure, List<ClassroomMember>>(
          ServerFailure('Invalid classroom member payload'),
        ),
      );
    });
  });

  group('getLevelDistributionOverview', () {
    test(
      'returns Right(LevelDistributionOverview) when datasource succeeds',
      () async {
        when(
          () => mockRemoteDataSource.getLevelDistributionOverview(
            tRequiredAuth,
            tAcademicYearId,
            tSchoolLevelId,
          ),
        ).thenAnswer((_) async => tLevelDistributionOverviewModel);

        final result = await repository.getLevelDistributionOverview(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        );

        result.fold(
          (_) => fail('Expected Right but got Left'),
          (overview) => expect(overview, tLevelDistributionOverview),
        );
        verify(
          () => mockRemoteDataSource.getLevelDistributionOverview(
            tRequiredAuth,
            tAcademicYearId,
            tSchoolLevelId,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.getLevelDistributionOverview(
            tRequiredAuth,
            tAcademicYearId,
            tSchoolLevelId,
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getLevelDistributionOverview(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        );

        expect(
          result,
          const Left<Failure, LevelDistributionOverview>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );
  });

  group('getClassroomStats', () {
    test('returns Right(ClassroomStats) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.getClassroomStats(tRequiredAuth),
      ).thenAnswer((_) async => tClassroomStatsResponseModel);

      final result = await repository.getClassroomStats();

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (stats) => expect(stats, tClassroomStats),
      );
      verify(
        () => mockRemoteDataSource.getClassroomStats(tRequiredAuth),
      ).called(1);
    });

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = UnauthorizedFailure('Access forbidden');
      when(
        () => mockRemoteDataSource.getClassroomStats(tRequiredAuth),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getClassroomStats();

      expect(result, const Left<Failure, ClassroomStats>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.getClassroomStats(tRequiredAuth),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getClassroomStats();

        expect(
          result,
          const Left<Failure, ClassroomStats>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );
  });

  group('distributeStudentsToClassrooms', () {
    test(
      'returns Right(void) and sends mapped request body on success',
      () async {
        when(
          () => mockRemoteDataSource.distributeStudentsToClassrooms(
            tRequiredAuth,
            any(),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.distributeStudentsToClassrooms(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        );

        expect(result.isRight(), true);
        final captured =
            verify(
                  () => mockRemoteDataSource.distributeStudentsToClassrooms(
                    tRequiredAuth,
                    captureAny(),
                  ),
                ).captured.single
                as DistributionRequestModel;

        expect(captured.academicYearId, tAcademicYearId);
        expect(captured.schoolLevelGroupId, tSchoolLevelGroupId);
        expect(captured.schoolLevelId, tSchoolLevelId);
        expect(captured.distributionCriterion, 'GENDER');
      },
    );

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = ValidationFailure('Invalid request data');
      when(
        () => mockRemoteDataSource.distributeStudentsToClassrooms(
          tRequiredAuth,
          any(),
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.distributeStudentsToClassrooms(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.percentage,
      );

      expect(result, const Left<Failure, void>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.distributeStudentsToClassrooms(
            tRequiredAuth,
            any(),
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.distributeStudentsToClassrooms(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        );

        expect(
          result,
          const Left<Failure, void>(NetworkFailure('Network error occurred')),
        );
      },
    );

    test('returns Left(ServerFailure) on unknown exception', () async {
      when(
        () => mockRemoteDataSource.distributeStudentsToClassrooms(
          tRequiredAuth,
          any(),
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.distributeStudentsToClassrooms(
        academicYearId: tAcademicYearId,
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.percentage,
      );

      expect(
        result,
        const Left<Failure, void>(ServerFailure('Unexpected error occurred')),
      );
    });
  });

  group('reassignClassroomMember', () {
    test(
      'returns Right(void) and sends target classroom payload on success',
      () async {
        when(
          () => mockRemoteDataSource.reassignClassroomMember(
            tRequiredAuth,
            tTargetClassroomId,
            tClassroomMemberId,
            any(),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.reassignClassroomMember(
          classroomMemberId: tClassroomMemberId,
          targetClassroomId: tTargetClassroomId,
        );

        expect(result.isRight(), true);
        final captured =
            verify(
                  () => mockRemoteDataSource.reassignClassroomMember(
                    tRequiredAuth,
                    tTargetClassroomId,
                    tClassroomMemberId,
                    captureAny(),
                  ),
                ).captured.single
                as ReassignClassroomMemberRequestModel;

        expect(captured.targetClassroomId, tTargetClassroomId);
      },
    );

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = NotFoundFailure('Resource not found');
      when(
        () => mockRemoteDataSource.reassignClassroomMember(
          tRequiredAuth,
          tTargetClassroomId,
          tClassroomMemberId,
          any(),
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.reassignClassroomMember(
        classroomMemberId: tClassroomMemberId,
        targetClassroomId: tTargetClassroomId,
      );

      expect(result, const Left<Failure, void>(failure));
    });
  });
}

DioException _dioException({Object? error}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/classrooms'),
    error: error,
    type: DioExceptionType.unknown,
  );
}
