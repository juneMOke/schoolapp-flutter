import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/reassign_member_online_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';

class MockSyncClassroomsUseCase extends Mock implements SyncClassroomsUseCase {}

class MockGetOfflineClassroomsUseCase extends Mock
    implements GetOfflineClassroomsUseCase {}

class MockGetOfflineRosterUseCase extends Mock
    implements GetOfflineRosterUseCase {}

class MockReassignMemberOnlineUseCase extends Mock
    implements ReassignMemberOnlineUseCase {}

const tAcademicYearId = 'year-1';
const tSchoolLevelId = 'level-1';
const tClassroomId = 'classroom-1';
const tTargetClassroomId = 'classroom-2';
const tClassroomMemberId = 'member-1';

const tOfflineClassroom = OfflineClassroom(
  id: tClassroomId,
  academicYearId: tAcademicYearId,
  schoolLevelId: tSchoolLevelId,
  name: 'A1',
  totalCount: 32,
  femaleCount: 16,
  maleCount: 16,
);

const tClassroomMember = ClassroomMember(
  id: tClassroomMemberId,
  studentId: 'student-1',
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: ClassroomMemberGender.male,
);

const tSyncOutcome = ClassroomSyncOutcome(
  classroomsUpserted: 3,
  membersUpserted: 40,
  notModified: false,
  syncedAt: 1720000000000,
  cursor: '2026-06-06T08:00:00.000Z',
);

void main() {
  late MockSyncClassroomsUseCase mockSyncClassrooms;
  late MockGetOfflineClassroomsUseCase mockGetClassrooms;
  late MockGetOfflineRosterUseCase mockGetRoster;
  late MockReassignMemberOnlineUseCase mockReassignMember;

  setUp(() {
    mockSyncClassrooms = MockSyncClassroomsUseCase();
    mockGetClassrooms = MockGetOfflineClassroomsUseCase();
    mockGetRoster = MockGetOfflineRosterUseCase();
    mockReassignMember = MockReassignMemberOnlineUseCase();
  });

  ClassroomOfflineBloc buildBloc() => ClassroomOfflineBloc(
    syncClassrooms: mockSyncClassrooms,
    getClassrooms: mockGetClassrooms,
    getRoster: mockGetRoster,
    reassignMember: mockReassignMember,
  );

  group('ClassroomsSyncRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] et dérive la fraîcheur du syncedAt',
      setUp: () {
        when(
          () => mockSyncClassrooms(academicYearId: tAcademicYearId),
        ).thenAnswer((_) async => const Right(tSyncOutcome));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomsSyncRequested(academicYearId: tAcademicYearId),
      ),
      expect: () => const [
        ClassroomOfflineState(syncStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          syncStatus: ClassroomStatus.success,
          freshness: 1720000000000,
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, failure] on NetworkFailure',
      setUp: () {
        when(
          () => mockSyncClassrooms(academicYearId: tAcademicYearId),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomsSyncRequested(academicYearId: tAcademicYearId),
      ),
      expect: () => const [
        ClassroomOfflineState(syncStatus: ClassroomStatus.loading),
        ClassroomOfflineState(syncStatus: ClassroomStatus.failure),
      ],
    );
  });

  group('OfflineClassroomsRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] quand les classes locales sont chargées',
      setUp: () {
        when(
          () => mockGetClassrooms(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        ).thenAnswer((_) async => const Right([tOfflineClassroom]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineClassroomsRequested(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(classroomsStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          classroomsStatus: ClassroomStatus.success,
          classrooms: [tOfflineClassroom],
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits failure avec storage errorType sur StorageFailure',
      setUp: () {
        when(
          () => mockGetClassrooms(
            academicYearId: tAcademicYearId,
            schoolLevelId: null,
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('db')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineClassroomsRequested(academicYearId: tAcademicYearId),
      ),
      expect: () => const [
        ClassroomOfflineState(classroomsStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          classroomsStatus: ClassroomStatus.failure,
          classroomsErrorType: ClassroomErrorType.storage,
        ),
      ],
    );
  });

  group('OfflineRosterRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] quand le roster local est chargé',
      setUp: () {
        when(
          () => mockGetRoster(classroomId: tClassroomId, query: null),
        ).thenAnswer((_) async => const Right([tClassroomMember]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const OfflineRosterRequested(classroomId: tClassroomId)),
      expect: () => const [
        ClassroomOfflineState(rosterStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          rosterStatus: ClassroomStatus.success,
          roster: [tClassroomMember],
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits failure avec notFound errorType sur NotFoundFailure',
      setUp: () {
        when(
          () => mockGetRoster(classroomId: tClassroomId, query: 'doe'),
        ).thenAnswer((_) async => const Left(NotFoundFailure('none')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineRosterRequested(classroomId: tClassroomId, query: 'doe'),
      ),
      expect: () => const [
        ClassroomOfflineState(rosterStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          rosterStatus: ClassroomStatus.failure,
          rosterErrorType: ClassroomErrorType.notFound,
        ),
      ],
    );
  });

  group('MemberReassignRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Right(true) → [loading, success] sans re-pull en échec',
      setUp: () {
        when(
          () => mockReassignMember(
            classroomMemberId: tClassroomMemberId,
            targetClassroomId: tTargetClassroomId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberReassignRequested(
          classroomMemberId: tClassroomMemberId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          reassignStatus: ClassroomStatus.loading,
          reassigningMemberId: tClassroomMemberId,
        ),
        ClassroomOfflineState(reassignStatus: ClassroomStatus.success),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Right(false) → succès partiel (reassignRePullFailed = true)',
      setUp: () {
        when(
          () => mockReassignMember(
            classroomMemberId: tClassroomMemberId,
            targetClassroomId: tTargetClassroomId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right(false));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberReassignRequested(
          classroomMemberId: tClassroomMemberId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          reassignStatus: ClassroomStatus.loading,
          reassigningMemberId: tClassroomMemberId,
        ),
        ClassroomOfflineState(
          reassignStatus: ClassroomStatus.success,
          reassignRePullFailed: true,
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Left → [loading, failure] avec network errorType (déplacement KO)',
      setUp: () {
        when(
          () => mockReassignMember(
            classroomMemberId: tClassroomMemberId,
            targetClassroomId: tTargetClassroomId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberReassignRequested(
          classroomMemberId: tClassroomMemberId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          reassignStatus: ClassroomStatus.loading,
          reassigningMemberId: tClassroomMemberId,
        ),
        ClassroomOfflineState(
          reassignStatus: ClassroomStatus.failure,
          reassignErrorType: ClassroomErrorType.network,
        ),
      ],
    );
  });
}
