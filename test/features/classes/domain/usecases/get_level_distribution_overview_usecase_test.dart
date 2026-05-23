import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_level_distribution_overview_usecase.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

const tAcademicYearId = 'year-1';
const tSchoolLevelId = 'level-1';

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

const tClassroom = Classroom(
  id: 'classroom-1',
  schoolLevelGroupId: 'group-1',
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

const tClassroomMember = ClassroomMember(
  id: 'member-1',
  studentId: 'student-1',
  classroomId: 'classroom-1',
  academicYearId: tAcademicYearId,
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: ClassroomMemberGender.male,
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
  late MockClassroomRepository mockRepository;
  late GetLevelDistributionOverviewUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = GetLevelDistributionOverviewUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.getLevelDistributionOverview(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => const Right(tLevelDistributionOverview));

    final result = await useCase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    result.fold(
      (_) => fail('Expected Right but got Left'),
      (overview) => expect(overview, tLevelDistributionOverview),
    );
    verify(
      () => mockRepository.getLevelDistributionOverview(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NetworkFailure('Network error occurred');
    when(
      () => mockRepository.getLevelDistributionOverview(
        academicYearId: tAcademicYearId,
        schoolLevelId: tSchoolLevelId,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      academicYearId: tAcademicYearId,
      schoolLevelId: tSchoolLevelId,
    );

    expect(result, const Left<Failure, LevelDistributionOverview>(failure));
  });
}
