import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_members_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

class MockGetClassroomsUseCase extends Mock implements GetClassroomsUseCase {}

class MockDistributeStudentsToClassroomsUseCase extends Mock
    implements DistributeStudentsToClassroomsUseCase {}

class MockGetClassroomMembersUseCase extends Mock
    implements GetClassroomMembersUseCase {}

const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';
const tClassroomId = 'classroom-1';

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

void main() {
  late MockGetClassroomsUseCase mockGetClassroomsUseCase;
  late MockGetClassroomMembersUseCase mockGetClassroomMembersUseCase;
  late MockDistributeStudentsToClassroomsUseCase
  mockDistributeStudentsToClassroomsUseCase;

  setUp(() {
    mockGetClassroomsUseCase = MockGetClassroomsUseCase();
    mockGetClassroomMembersUseCase = MockGetClassroomMembersUseCase();
    mockDistributeStudentsToClassroomsUseCase =
        MockDistributeStudentsToClassroomsUseCase();
  });

  ClassroomBloc buildBloc() => ClassroomBloc(
    getClassroomsUseCase: mockGetClassroomsUseCase,
    getClassroomMembersUseCase: mockGetClassroomMembersUseCase,
    distributeStudentsToClassroomsUseCase:
        mockDistributeStudentsToClassroomsUseCase,
  );

  group('ClassroomRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits [loading, success] when classrooms are loaded',
      setUp: () {
        when(
          () => mockGetClassroomsUseCase(
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right([tClassroom]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomRequested(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(status: ClassroomStatus.loading),
        ClassroomState(
          status: ClassroomStatus.success,
          classrooms: [tClassroom],
        ),
      ],
    );

    blocTest<ClassroomBloc, ClassroomState>(
      'emits failure with notFound error type on NotFoundFailure',
      setUp: () {
        when(
          () => mockGetClassroomsUseCase(
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(NotFoundFailure('Not found')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomRequested(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(status: ClassroomStatus.loading),
        ClassroomState(
          status: ClassroomStatus.failure,
          errorType: ClassroomErrorType.notFound,
        ),
      ],
    );
  });

  group('ClassroomResetRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits initial state when reset is requested',
      build: buildBloc,
      seed: () => const ClassroomState(
        status: ClassroomStatus.success,
        classrooms: [tClassroom],
      ),
      act: (bloc) => bloc.add(const ClassroomResetRequested()),
      expect: () => const [ClassroomState()],
    );
  });

  group('ClassroomDistributionRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits distribution [loading, success] when distribution succeeds',
      setUp: () {
        when(
          () => mockDistributeStudentsToClassroomsUseCase(
            academicYearId: tAcademicYearId,
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            distributionCriterion: ClassroomDistributionCriterion.gender,
          ),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomDistributionRequested(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.gender,
        ),
      ),
      expect: () => const [
        ClassroomState(distributionStatus: ClassroomStatus.loading),
        ClassroomState(distributionStatus: ClassroomStatus.success),
      ],
    );

    blocTest<ClassroomBloc, ClassroomState>(
      'emits distribution failure with validation error type on ValidationFailure',
      setUp: () {
        when(
          () => mockDistributeStudentsToClassroomsUseCase(
            academicYearId: tAcademicYearId,
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            distributionCriterion: ClassroomDistributionCriterion.percentage,
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomDistributionRequested(
          academicYearId: tAcademicYearId,
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          distributionCriterion: ClassroomDistributionCriterion.percentage,
        ),
      ),
      expect: () => const [
        ClassroomState(distributionStatus: ClassroomStatus.loading),
        ClassroomState(
          distributionStatus: ClassroomStatus.failure,
          distributionErrorType: ClassroomErrorType.validation,
        ),
      ],
    );
  });

  group('ClassroomMembersRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits members [loading, success] when classroom members are loaded',
      setUp: () {
        when(
          () => mockGetClassroomMembersUseCase(
            classroomId: tClassroomId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right([tClassroomMember]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomMembersRequested(
          classroomId: tClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(membersStatus: ClassroomStatus.loading),
        ClassroomState(
          membersStatus: ClassroomStatus.success,
          members: [tClassroomMember],
        ),
      ],
    );

    blocTest<ClassroomBloc, ClassroomState>(
      'emits members failure with notFound error type on NotFoundFailure',
      setUp: () {
        when(
          () => mockGetClassroomMembersUseCase(
            classroomId: tClassroomId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(NotFoundFailure('Not found')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomMembersRequested(
          classroomId: tClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(membersStatus: ClassroomStatus.loading),
        ClassroomState(
          membersStatus: ClassroomStatus.failure,
          membersErrorType: ClassroomErrorType.notFound,
        ),
      ],
    );
  });
}
