import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/reassign_member_online_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/record_classroom_transfer_usecase.dart';
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

class MockGetComposedRostersUseCase extends Mock
    implements GetComposedRostersUseCase {}

class MockReassignMemberOnlineUseCase extends Mock
    implements ReassignMemberOnlineUseCase {}

class MockRecordClassroomTransferUseCase extends Mock
    implements RecordClassroomTransferUseCase {}

class FakeRecordClassroomTransferDraft extends Fake
    implements RecordClassroomTransferDraft {}

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
);

void main() {
  late MockSyncClassroomsUseCase mockSyncClassrooms;
  late MockGetOfflineClassroomsUseCase mockGetClassrooms;
  late MockGetOfflineRosterUseCase mockGetRoster;
  late MockGetComposedRostersUseCase mockGetComposedRosters;
  late MockRecordClassroomTransferUseCase mockRecordTransfer;
  late MockReassignMemberOnlineUseCase mockReassignMember;

  setUpAll(() {
    registerFallbackValue(FakeRecordClassroomTransferDraft());
  });

  setUp(() {
    mockSyncClassrooms = MockSyncClassroomsUseCase();
    mockGetClassrooms = MockGetOfflineClassroomsUseCase();
    mockGetRoster = MockGetOfflineRosterUseCase();
    mockGetComposedRosters = MockGetComposedRostersUseCase();
    mockRecordTransfer = MockRecordClassroomTransferUseCase();
    mockReassignMember = MockReassignMemberOnlineUseCase();
    // Par défaut, le rechargement des rosters composés post-transfert renvoie {}.
    when(
      () => mockGetComposedRosters(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
      ),
    ).thenAnswer((_) async => const Right({}));
  });

  ClassroomOfflineBloc buildBloc() => ClassroomOfflineBloc(
    syncClassrooms: mockSyncClassrooms,
    getClassrooms: mockGetClassrooms,
    getRoster: mockGetRoster,
    getComposedRosters: mockGetComposedRosters,
    recordTransfer: mockRecordTransfer,
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

  group('OfflineClassroomsRequested (année complète, dropdowns)', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] quand les classes locales sont chargées',
      setUp: () {
        when(
          () => mockGetClassrooms(academicYearId: tAcademicYearId),
        ).thenAnswer((_) async => const Right([tOfflineClassroom]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineClassroomsRequested(academicYearId: tAcademicYearId),
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
          () => mockGetClassrooms(academicYearId: tAcademicYearId),
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

  group('OfflineLevelClassroomsRequested (working-set dédié Organisation, '
      'jamais partagé avec OfflineClassroomsRequested)', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] dans levelClassrooms — classrooms (année '
      'complète) reste intact',
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
        const OfflineLevelClassroomsRequested(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(levelClassroomsStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          levelClassroomsStatus: ClassroomStatus.success,
          levelClassrooms: [tOfflineClassroom],
        ),
      ],
      verify: (bloc) => expect(bloc.state.classrooms, isEmpty),
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits failure avec storage errorType sur StorageFailure',
      setUp: () {
        when(
          () => mockGetClassrooms(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('db')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineLevelClassroomsRequested(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(levelClassroomsStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          levelClassroomsStatus: ClassroomStatus.failure,
          levelClassroomsErrorType: ClassroomErrorType.storage,
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

  group('MemberTransferRequested (offline)', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'succès → [loading, pending-sync] (événement enfilé)',
      setUp: () {
        when(
          () => mockRecordTransfer(any()),
        ).thenAnswer((_) async => const Right('transfer-1'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberTransferRequested(
          studentId: 'student-1',
          fromClassroomId: tClassroomId,
          toClassroomId: tTargetClassroomId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          transferStatus: ClassroomStatus.loading,
          transferringStudentId: 'student-1',
        ),
        ClassroomOfflineState(
          transferStatus: ClassroomStatus.success,
          transferPendingSync: true,
        ),
        // Rechargement optimiste des rosters composés du niveau.
        ClassroomOfflineState(
          transferStatus: ClassroomStatus.success,
          transferPendingSync: true,
          levelRostersStatus: ClassroomStatus.success,
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'échec local → [loading, failure] avec storage errorType',
      setUp: () {
        when(
          () => mockRecordTransfer(any()),
        ).thenAnswer((_) async => const Left(StorageFailure('db')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberTransferRequested(
          studentId: 'student-1',
          fromClassroomId: tClassroomId,
          toClassroomId: tTargetClassroomId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          transferStatus: ClassroomStatus.loading,
          transferringStudentId: 'student-1',
        ),
        ClassroomOfflineState(
          transferStatus: ClassroomStatus.failure,
          transferErrorType: ClassroomErrorType.storage,
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
