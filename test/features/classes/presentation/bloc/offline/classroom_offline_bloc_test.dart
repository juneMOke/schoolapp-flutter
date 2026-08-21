import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_unassigned_level_enrollments_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/assign_enrollment_to_classroom_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/record_classroom_transfer_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class MockSyncClassroomsUseCase extends Mock implements SyncClassroomsUseCase {}

class MockGetOfflineClassroomsUseCase extends Mock
    implements GetOfflineClassroomsUseCase {}

class MockGetOfflineRosterUseCase extends Mock
    implements GetOfflineRosterUseCase {}

class MockGetComposedRostersUseCase extends Mock
    implements GetComposedRostersUseCase {}

class MockGetUnassignedLevelEnrollmentsUseCase extends Mock
    implements GetUnassignedLevelEnrollmentsUseCase {}

class MockAssignEnrollmentToClassroomUseCase extends Mock
    implements AssignEnrollmentToClassroomUseCase {}

class MockRecordClassroomTransferUseCase extends Mock
    implements RecordClassroomTransferUseCase {}

class FakeRecordClassroomTransferDraft extends Fake
    implements RecordClassroomTransferDraft {}

const tAcademicYearId = 'year-1';
const tSchoolLevelId = 'level-1';
const tClassroomId = 'classroom-1';
const tTargetClassroomId = 'classroom-2';
const tClassroomMemberId = 'member-1';
const tEnrollmentId = 'enrollment-1';

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

const tUnassignedEnrollment = EnrollmentSummary(
  enrollmentId: 'enrollment-9',
  enrollmentCode: 'MAT-9',
  status: 'COMPLETED',
  student: StudentSummary(
    id: 'student-9',
    firstName: 'Awa',
    lastName: 'Ndiaye',
    surname: 'Fatou',
    dateOfBirth: '2012-05-01',
    gender: Gender.female,
  ),
);

void main() {
  late MockSyncClassroomsUseCase mockSyncClassrooms;
  late MockGetOfflineClassroomsUseCase mockGetClassrooms;
  late MockGetOfflineRosterUseCase mockGetRoster;
  late MockGetComposedRostersUseCase mockGetComposedRosters;
  late MockGetUnassignedLevelEnrollmentsUseCase mockGetUnassignedEnrollments;
  late MockRecordClassroomTransferUseCase mockRecordTransfer;
  late MockAssignEnrollmentToClassroomUseCase mockAssignEnrollment;

  setUpAll(() {
    registerFallbackValue(FakeRecordClassroomTransferDraft());
  });

  setUp(() {
    mockSyncClassrooms = MockSyncClassroomsUseCase();
    mockGetClassrooms = MockGetOfflineClassroomsUseCase();
    mockGetRoster = MockGetOfflineRosterUseCase();
    mockGetComposedRosters = MockGetComposedRostersUseCase();
    mockGetUnassignedEnrollments = MockGetUnassignedLevelEnrollmentsUseCase();
    mockRecordTransfer = MockRecordClassroomTransferUseCase();
    mockAssignEnrollment = MockAssignEnrollmentToClassroomUseCase();
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
    getUnassignedEnrollments: mockGetUnassignedEnrollments,
    recordTransfer: mockRecordTransfer,
    assignEnrollment: mockAssignEnrollment,
  );

  // Depuis ADR-015 F6 le pull passe par le `PullCoordinator` : le use case rend
  // un bilan de cycle, pas un `Either`. Le BLoC ne demande donc plus « le cycle
  // s'est-il bien passé ? » — un cycle complet répondrait pour des flux
  // étrangers à cet écran — mais « MES deux ressources sont-elles passées ? ».
  group('ClassroomsSyncRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] quand les DEUX ressources sont tirées',
      setUp: () {
        when(() => mockSyncClassrooms()).thenAnswer(
          (_) async => const PullRunReport(
            updated: 1,
            notModified: 1,
            outcomes: {
              kClassroomsResource: PullResult.updated,
              kClassroomMembersResource: PullResult.notModified,
            },
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClassroomsSyncRequested()),
      expect: () => const [
        ClassroomOfflineState(syncStatus: ClassroomStatus.loading),
        ClassroomOfflineState(syncStatus: ClassroomStatus.success),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, failure] quand une seule des deux est tirée',
      // Le roster en échec avec les classes à jour est le pire des deux
      // mondes affichables : des classes fraîches et des effectifs périmés.
      // Annoncer « synchronisé » là-dessus serait un mensonge.
      setUp: () {
        when(() => mockSyncClassrooms()).thenAnswer(
          (_) async => const PullRunReport(
            updated: 1,
            failed: 1,
            outcomes: {
              kClassroomsResource: PullResult.updated,
              kClassroomMembersResource: PullResult.error,
            },
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClassroomsSyncRequested()),
      expect: () => const [
        ClassroomOfflineState(syncStatus: ClassroomStatus.loading),
        ClassroomOfflineState(syncStatus: ClassroomStatus.failure),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, failure] hors-ligne : un cycle sans issue n\'est pas '
      'un succès',
      // `PullRunReport.offline()` ne porte AUCUNE issue : `succeeded` rend
      // `false` pour les deux ressources — sautées, jamais tentées. Sans cette
      // lecture, un `failed == 0` ferait passer un cache froid pour à jour.
      setUp: () {
        when(
          () => mockSyncClassrooms(),
        ).thenAnswer((_) async => const PullRunReport.offline());
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ClassroomsSyncRequested()),
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

  group('OfflineLevelUnassignedEnrollmentsRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits [loading, success] avec les non-affectés calculés offline',
      setUp: () {
        when(
          () => mockGetUnassignedEnrollments(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        ).thenAnswer((_) async => const Right([tUnassignedEnrollment]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineLevelUnassignedEnrollmentsRequested(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(levelUnassignedStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          levelUnassignedStatus: ClassroomStatus.success,
          levelUnassignedEnrollments: [tUnassignedEnrollment],
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'emits failure avec storage errorType sur StorageFailure',
      setUp: () {
        when(
          () => mockGetUnassignedEnrollments(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('db')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const OfflineLevelUnassignedEnrollmentsRequested(
          academicYearId: tAcademicYearId,
          schoolLevelId: tSchoolLevelId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(levelUnassignedStatus: ClassroomStatus.loading),
        ClassroomOfflineState(
          levelUnassignedStatus: ClassroomStatus.failure,
          levelUnassignedErrorType: ClassroomErrorType.storage,
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'un échec APRÈS un succès purge la liste (jamais un effectif périmé '
      'affiché comme fiable)',
      setUp: () {
        final answers = [
          const Right<Failure, List<EnrollmentSummary>>([
            tUnassignedEnrollment,
          ]),
          const Left<Failure, List<EnrollmentSummary>>(StorageFailure('db')),
        ];
        when(
          () => mockGetUnassignedEnrollments(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        ).thenAnswer((_) async => answers.removeAt(0));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const OfflineLevelUnassignedEnrollmentsRequested(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const OfflineLevelUnassignedEnrollmentsRequested(
            academicYearId: tAcademicYearId,
            schoolLevelId: tSchoolLevelId,
          ),
        );
      },
      skip: 2, // loading + success du premier appel
      expect: () => const [
        ClassroomOfflineState(
          levelUnassignedStatus: ClassroomStatus.loading,
          levelUnassignedEnrollments: [tUnassignedEnrollment],
        ),
        ClassroomOfflineState(
          levelUnassignedStatus: ClassroomStatus.failure,
          levelUnassignedEnrollments: [],
          levelUnassignedErrorType: ClassroomErrorType.storage,
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

  group('MemberAssignRequested', () {
    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Right(true) → [loading, success] miroir local à jour',
      setUp: () {
        when(
          () => mockAssignEnrollment(
            classroomId: tTargetClassroomId,
            enrollmentId: tEnrollmentId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberAssignRequested(
          enrollmentId: tEnrollmentId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          assignStatus: ClassroomStatus.loading,
          assigningEnrollmentId: tEnrollmentId,
        ),
        ClassroomOfflineState(assignStatus: ClassroomStatus.success),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Right(false) → succès partiel (assignRePullFailed = true)',
      setUp: () {
        when(
          () => mockAssignEnrollment(
            classroomId: tTargetClassroomId,
            enrollmentId: tEnrollmentId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right(false));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberAssignRequested(
          enrollmentId: tEnrollmentId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          assignStatus: ClassroomStatus.loading,
          assigningEnrollmentId: tEnrollmentId,
        ),
        ClassroomOfflineState(
          assignStatus: ClassroomStatus.success,
          assignRePullFailed: true,
        ),
      ],
    );

    blocTest<ClassroomOfflineBloc, ClassroomOfflineState>(
      'Left → [loading, failure] avec network errorType (affectation KO)',
      setUp: () {
        when(
          () => mockAssignEnrollment(
            classroomId: tTargetClassroomId,
            enrollmentId: tEnrollmentId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const MemberAssignRequested(
          enrollmentId: tEnrollmentId,
          targetClassroomId: tTargetClassroomId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomOfflineState(
          assignStatus: ClassroomStatus.loading,
          assigningEnrollmentId: tEnrollmentId,
        ),
        ClassroomOfflineState(
          assignStatus: ClassroomStatus.failure,
          assignErrorType: ClassroomErrorType.network,
        ),
      ],
    );
  });
}
