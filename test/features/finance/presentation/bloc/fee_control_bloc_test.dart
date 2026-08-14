import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_charge_aggregates_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_tariffs_for_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';

class MockSearchLocalEnrollmentsUseCase extends Mock
    implements SearchLocalEnrollmentsUseCase {}

class MockGetFeeChargeAggregatesUseCase extends Mock
    implements GetFeeChargeAggregatesUseCase {}

class MockGetFeeTariffsForLevelUseCase extends Mock
    implements GetFeeTariffsForLevelUseCase {}

class MockHasFeeGridUseCase extends Mock implements HasFeeGridUseCase {}

class MockGetOfflineClassroomsUseCase extends Mock
    implements GetOfflineClassroomsUseCase {}

class MockGetOfflineRosterUseCase extends Mock
    implements GetOfflineRosterUseCase {}

const tYear = 'ay-1';
const tGroup = 'grp-1';
const tLevel = 'lvl-1';
const tFeeCode = 'TUITION';

LocalEnrollmentListItem student(String id, {String lastName = 'MOKE'}) =>
    LocalEnrollmentListItem(
      enrollmentId: 'enr-$id',
      studentId: id,
      firstName: 'Prénom$id',
      lastName: lastName,
      surname: 'Post$id',
      dateOfBirth: '2010-01-01',
      gender: OfflineGender.male,
      enrollmentType: EnrollmentType.newEnrollment,
      status: OfflineEnrollmentStatus.completed,
      enrollmentDate: '2026-01-01',
      syncState: SyncState.synced,
    );

LocalFeeChargeAggregate aggregate(
  String studentId, {
  int expected = 100000,
  int mirror = 0,
  int pending = 0,
}) => LocalFeeChargeAggregate(
  studentId: studentId,
  expectedInCents: expected,
  paidMirrorInCents: mirror,
  paidPendingInCents: pending,
  currency: 'USD',
);

const tTariff = LocalFeeTariff(
  id: 't-1',
  feeCode: tFeeCode,
  label: 'Frais scolaire',
  amountInCents: 100000,
  currency: 'USD',
);

const tClassroom = OfflineClassroom(
  id: 'cls-1',
  academicYearId: tYear,
  schoolLevelId: tLevel,
  name: '1ère A',
  totalCount: 0,
  femaleCount: 0,
  maleCount: 0,
);

ClassroomMember member(String studentId) => ClassroomMember(
  id: 'mem-$studentId',
  studentId: studentId,
  classroomId: tClassroom.id,
  academicYearId: tYear,
  studentFirstName: 'Prénom$studentId',
  studentLastName: 'MOKE',
  studentGender: ClassroomMemberGender.male,
);

FeeControlSearchRequest request({
  FeeControlPaymentFilter filter = FeeControlPaymentFilter.all,
  String firstName = '',
  String lastName = '',
  String surname = '',
  String? classroomId,
}) => FeeControlSearchRequest(
  schoolLevelGroupId: tGroup,
  schoolLevelId: tLevel,
  classroomId: classroomId,
  feeCode: tFeeCode,
  statusFilter: filter,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
);

void main() {
  late MockSearchLocalEnrollmentsUseCase search;
  late MockGetFeeChargeAggregatesUseCase getAggregates;
  late MockGetFeeTariffsForLevelUseCase getTariffs;
  late MockHasFeeGridUseCase hasFeeGrid;
  late MockGetOfflineClassroomsUseCase getClassrooms;
  late MockGetOfflineRosterUseCase getRoster;

  setUp(() {
    search = MockSearchLocalEnrollmentsUseCase();
    getAggregates = MockGetFeeChargeAggregatesUseCase();
    getTariffs = MockGetFeeTariffsForLevelUseCase();
    hasFeeGrid = MockHasFeeGridUseCase();
    getClassrooms = MockGetOfflineClassroomsUseCase();
    getRoster = MockGetOfflineRosterUseCase();
  });

  FeeControlBloc buildBloc() => FeeControlBloc(
    search: search,
    getAggregates: getAggregates,
    getTariffs: getTariffs,
    hasFeeGrid: hasFeeGrid,
    getClassrooms: getClassrooms,
    getRoster: getRoster,
  );

  void stubEnrolled(List<LocalEnrollmentListItem> items) {
    when(
      () => search.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        schoolLevelId: any(named: 'schoolLevelId'),
      ),
    ).thenAnswer((_) async => Right(items));
  }

  void stubAggregates(List<LocalFeeChargeAggregate> rows) {
    when(
      () => getAggregates(
        academicYearId: any(named: 'academicYearId'),
        feeCode: any(named: 'feeCode'),
        studentIds: any(named: 'studentIds'),
      ),
    ).thenAnswer((_) async => Right(rows));
  }

  group('FeeControlTariffsRequested', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'expose la grille du niveau',
      setUp: () {
        when(
          () => getTariffs(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Right([tTariff]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlTariffsRequested(
          academicYearId: tYear,
          schoolLevelGroupId: tGroup,
          schoolLevelId: tLevel,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.tariffsStatus, EnrollmentLoadStatus.success);
        expect(bloc.state.tariffs, const [tTariff]);
        expect(bloc.state.feeGridMissing, isFalse);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'grille vide + référentiel présent → « ce niveau n\'a pas de frais »',
      setUp: () {
        when(
          () => getTariffs(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Right(<LocalFeeTariff>[]));
        when(
          () => hasFeeGrid(any()),
        ).thenAnswer((_) async => const Right(true));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlTariffsRequested(
          academicYearId: tYear,
          schoolLevelGroupId: tGroup,
          schoolLevelId: tLevel,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.tariffs, isEmpty);
        expect(bloc.state.feeGridMissing, isFalse);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'grille vide + référentiel absent → « grille absente de l\'appareil »',
      setUp: () {
        when(
          () => getTariffs(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Right(<LocalFeeTariff>[]));
        when(
          () => hasFeeGrid(any()),
        ).thenAnswer((_) async => const Right(false));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlTariffsRequested(
          academicYearId: tYear,
          schoolLevelGroupId: tGroup,
          schoolLevelId: tLevel,
        ),
      ),
      verify: (bloc) => expect(bloc.state.feeGridMissing, isTrue),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'sonde en échec → fail-closed, grille annoncée absente',
      setUp: () {
        when(
          () => getTariffs(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Right(<LocalFeeTariff>[]));
        when(() => hasFeeGrid(any())).thenAnswer(
          (_) async => const Left(StorageFailure('base illisible')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlTariffsRequested(
          academicYearId: tYear,
          schoolLevelGroupId: tGroup,
          schoolLevelId: tLevel,
        ),
      ),
      verify: (bloc) => expect(bloc.state.feeGridMissing, isTrue),
    );
  });

  group('FeeControlSearchRequested', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'croise les élèves et leurs créances',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubAggregates([
          aggregate('s1', mirror: 100000),
          aggregate('s2', mirror: 40000),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.success);
        expect(bloc.state.rows.length, 2);
        expect(bloc.state.totalElements, 2);
        expect(bloc.state.studentsInScope, 2);
        expect(bloc.state.breakdown.total, 2);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'la répartition compte TOUTE la population, pas le sous-ensemble filtré',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubAggregates([
          aggregate('s1', mirror: 100000),
          aggregate('s2', mirror: 30000),
          aggregate('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.settled),
        ),
      ),
      verify: (bloc) {
        // Le tableau ne montre qu'un élève…
        expect(bloc.state.rows.length, 1);
        // …mais le bandeau annonce toujours l'état de la classe entière.
        expect(bloc.state.breakdown.settled, 1);
        expect(bloc.state.breakdown.partial, 1);
        expect(bloc.state.breakdown.none, 1);
        expect(bloc.state.breakdown.total, 3);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'un élève sans créance de ce frais est écarté',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubAggregates([aggregate('s1')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.map((r) => r.summary.student.id), ['s1']);
        expect(bloc.state.studentsInScope, 2);
        expect(bloc.state.breakdown.total, 1);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'filtre « soldé » : le reste composé fait foi, pas la colonne status',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubAggregates([
          // Soldé uniquement grâce à un encaissement pas encore remonté.
          aggregate('s1', mirror: 40000, pending: 60000),
          aggregate('s2', mirror: 30000),
          aggregate('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.settled),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.summary.student.id), ['s1']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'filtre « partiel »',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubAggregates([
          aggregate('s1', mirror: 100000),
          aggregate('s2', mirror: 30000),
          aggregate('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.partial),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.summary.student.id), ['s2']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'filtre « aucun paiement »',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubAggregates([
          aggregate('s1', mirror: 100000),
          aggregate('s2', mirror: 30000),
          aggregate('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.none),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.summary.student.id), ['s3']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'affine sur le nom sans relire la base',
      setUp: () {
        stubEnrolled([
          student('s1', lastName: 'MOKE'),
          student('s2', lastName: 'KASONGO'),
        ]);
        stubAggregates([aggregate('s1'), aggregate('s2')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(lastName: 'kas'),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.summary.student.id), ['s2']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'aucun élève dans la classe → succès vide, sans lecture des créances',
      setUp: () => stubEnrolled(const []),
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.success);
        expect(bloc.state.rows, isEmpty);
        expect(bloc.state.studentsInScope, 0);
        verifyNever(
          () => getAggregates(
            academicYearId: any(named: 'academicYearId'),
            feeCode: any(named: 'feeCode'),
            studentIds: any(named: 'studentIds'),
          ),
        );
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'échec de la recherche d\'élèves → erreur serveur, liste purgée',
      setUp: () {
        when(
          () => search.currentYearEnrolled(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
            schoolLevelId: any(named: 'schoolLevelId'),
          ),
        ).thenAnswer(
          (_) async => const Left(StorageFailure('base illisible')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.failure);
        expect(bloc.state.errorType, EnrollmentErrorType.server);
        expect(bloc.state.rows, isEmpty);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'échec de la lecture des créances → erreur, liste purgée',
      setUp: () {
        stubEnrolled([student('s1')]);
        when(
          () => getAggregates(
            academicYearId: any(named: 'academicYearId'),
            feeCode: any(named: 'feeCode'),
            studentIds: any(named: 'studentIds'),
          ),
        ).thenAnswer(
          (_) async => const Left(StorageFailure('base illisible')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.failure);
        expect(bloc.state.rows, isEmpty);
      },
    );
  });

  group('FeeControlClassroomsRequested', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'expose les classes du niveau',
      setUp: () {
        when(
          () => getClassrooms(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
          ),
        ).thenAnswer((_) async => const Right([tClassroom]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlClassroomsRequested(
          academicYearId: tYear,
          schoolLevelId: tLevel,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.classroomsStatus, EnrollmentLoadStatus.success);
        expect(bloc.state.classrooms, const [tClassroom]);
      },
    );
  });

  group('maille classe', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'une classe choisie borne le périmètre à son roster composé',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubAggregates([aggregate('s1'), aggregate('s2'), aggregate('s3')]);
        when(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) async => Right([member('s1'), member('s3')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(classroomId: tClassroom.id),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.map((r) => r.summary.student.id), [
          's1',
          's3',
        ]);
        expect(bloc.state.studentsInScope, 2);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'sans classe choisie, le roster n\'est pas lu',
      setUp: () {
        stubEnrolled([student('s1')]);
        stubAggregates([aggregate('s1')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.length, 1);
        verifyNever(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        );
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'roster illisible → échec, aucune liste servie',
      setUp: () {
        stubEnrolled([student('s1')]);
        when(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(
          (_) async => const Left(StorageFailure('base illisible')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(classroomId: tClassroom.id),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.failure);
        expect(bloc.state.rows, isEmpty);
      },
    );
  });

  group('pagination', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'change de page sans relire la base',
      setUp: () {
        stubEnrolled(List.generate(12, (i) => student('s$i')));
        stubAggregates(List.generate(12, (i) => aggregate('s$i')));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(
            academicYearId: tYear,
            request: request(),
            size: 10,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FeeControlPageRequested(1));
      },
      verify: (bloc) {
        expect(bloc.state.page, 1);
        expect(bloc.state.rows.length, 2);
        expect(bloc.state.totalPages, 2);
        verify(
          () => getAggregates(
            academicYearId: any(named: 'academicYearId'),
            feeCode: any(named: 'feeCode'),
            studentIds: any(named: 'studentIds'),
          ),
        ).called(1);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'refuse de paginer tant que la liste n\'est pas settled',
      build: buildBloc,
      act: (bloc) => bloc.add(const FeeControlPageRequested(1)),
      expect: () => const <FeeControlState>[],
    );
  });

  group('reset', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'revient à l\'état initial',
      setUp: () {
        stubEnrolled([student('s1')]);
        stubAggregates([aggregate('s1')]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(academicYearId: tYear, request: request()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FeeControlResetRequested());
      },
      verify: (bloc) {
        expect(bloc.state, const FeeControlState.initial());
        expect(bloc.state.hasSearched, isFalse);
      },
    );
  });
}
