import 'dart:async';

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
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_natures_for_year_use_case.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';

class MockSearchLocalEnrollmentsUseCase extends Mock
    implements SearchLocalEnrollmentsUseCase {}

class MockGetRecoveryPositionsUseCase extends Mock
    implements GetRecoveryPositionsUseCase {}

class MockGetFeeNaturesForYearUseCase extends Mock
    implements GetFeeNaturesForYearUseCase {}

class MockGetComposedRostersUseCase extends Mock
    implements GetComposedRostersUseCase {}

class MockGetOfflineClassroomsUseCase extends Mock
    implements GetOfflineClassroomsUseCase {}

class MockGetOfflineRosterUseCase extends Mock
    implements GetOfflineRosterUseCase {}

const tYear = 'ay-1';
const tLevel = 'lvl-1';
const tFeeCode = 'TUITION';
const tOtherFee = 'SUPPLIES';

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

/// Une ligne de registre : un élève, un frais, une devise.
LocalRecoveryLine ledger(
  String studentId, {
  String feeCode = tFeeCode,
  int expected = 100000,
  int mirror = 0,
  int pending = 0,
  String currency = 'USD',
  String? schoolLevelId = tLevel,
}) => LocalRecoveryLine(
  schoolLevelId: schoolLevelId,
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: feeCode,
      position: FeeChargePosition(
        currency: currency,
        expectedInCents: expected,
        paidMirrorInCents: mirror,
        paidPendingInCents: pending,
      ),
    ),
  ],
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

ClassroomMember member(String studentId, {String classroomId = 'cls-1'}) =>
    ClassroomMember(
      id: 'mem-$studentId',
      studentId: studentId,
      classroomId: classroomId,
      academicYearId: tYear,
      studentFirstName: 'Prénom$studentId',
      studentLastName: 'MOKE',
      studentGender: ClassroomMemberGender.male,
    );

FeeControlSearchRequest request({
  FeeControlPaymentFilter filter = FeeControlPaymentFilter.all,
  List<String> feeCodes = const [tFeeCode],
  int? thresholdInCents,
  String classroomId = 'cls-1',
}) => FeeControlSearchRequest(
  classroomId: classroomId,
  feeCodes: feeCodes,
  statusFilter: filter,
  thresholdInCents: thresholdInCents,
);

void main() {
  late MockSearchLocalEnrollmentsUseCase search;
  late MockGetRecoveryPositionsUseCase getPositions;
  late MockGetFeeNaturesForYearUseCase getNatures;
  late MockGetComposedRostersUseCase getComposedRosters;
  late MockGetOfflineClassroomsUseCase getClassrooms;
  late MockGetOfflineRosterUseCase getRoster;

  setUp(() {
    search = MockSearchLocalEnrollmentsUseCase();
    getPositions = MockGetRecoveryPositionsUseCase();
    getNatures = MockGetFeeNaturesForYearUseCase();
    getComposedRosters = MockGetComposedRostersUseCase();
    getClassrooms = MockGetOfflineClassroomsUseCase();
    getRoster = MockGetOfflineRosterUseCase();
  });

  FeeControlBloc buildBloc() => FeeControlBloc(
    search: search,
    getPositions: getPositions,
    getNatures: getNatures,
    getClassrooms: getClassrooms,
    getRoster: getRoster,
    getComposedRosters: getComposedRosters,
  );

  /// Les inscrits de l'année, ET — par défaut — le roster de la classe
  /// `cls-1` qui les contient tous : la v2 lit toujours une classe (ou la
  /// rubrique « Non affectés »), jamais un niveau entier.
  void stubEnrolled(
    List<LocalEnrollmentListItem> items, {
    bool inClassroom = true,
  }) {
    when(
      () => search.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => Right(items));
    if (!inClassroom) return;
    when(
      () => getRoster(
        classroomId: any(named: 'classroomId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => Right([for (final i in items) member(i.studentId)]),
    );
  }

  void stubPositions(List<LocalRecoveryLine> lines) {
    when(
      () => getPositions(
        academicYearId: any(named: 'academicYearId'),
        feeCodes: any(named: 'feeCodes'),
      ),
    ).thenAnswer((_) async => Right(lines));
  }

  group('FeeControlSearchRequested', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'croise les élèves et leurs créances',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 40000),
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
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 30000),
          ledger('s3'),
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
      'un élève sans créance de ces frais est écarté',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([ledger('s1')]);
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
        stubPositions([
          // Soldé uniquement grâce à un encaissement pas encore remonté.
          ledger('s1', mirror: 40000, pending: 60000),
          ledger('s2', mirror: 30000),
          ledger('s3'),
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
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 30000),
          ledger('s3'),
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
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 30000),
          ledger('s3'),
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
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
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
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));
        when(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) async => const Right(<ClassroomMember>[]));
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
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));
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

  group('FeeControlCatalogRequested', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'expose les natures de l\'année (avec leurs devises) et TOUTES les '
      'classes de l\'année — le champ Classe unique',
      setUp: () {
        when(
          () => getNatures(academicYearId: any(named: 'academicYearId')),
        ).thenAnswer(
          (_) async => const Right([
            (feeCode: tFeeCode, currencies: ['USD']),
            (feeCode: tOtherFee, currencies: ['CDF', 'USD']),
          ]),
        );
        when(
          () => getClassrooms(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
          ),
        ).thenAnswer((_) async => const Right([tClassroom]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FeeControlCatalogRequested(academicYearId: tYear)),
      verify: (bloc) {
        expect(bloc.state.catalogStatus, EnrollmentLoadStatus.success);
        expect(bloc.state.natures, const [
          FeeNature(feeCode: tFeeCode, currencies: ['USD']),
          FeeNature(feeCode: tOtherFee, currencies: ['CDF', 'USD']),
        ]);
        expect(bloc.state.classrooms, const [tClassroom]);
        // Sans filtre de niveau : toutes les classes de l'année.
        final captured = verify(
          () => getClassrooms(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: captureAny(named: 'schoolLevelId'),
          ),
        ).captured;
        expect(captured.single, isNull);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'une lecture illisible donne un catalogue en échec',
      setUp: () {
        when(
          () => getNatures(academicYearId: any(named: 'academicYearId')),
        ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));
        when(
          () => getClassrooms(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
          ),
        ).thenAnswer((_) async => const Right([tClassroom]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FeeControlCatalogRequested(academicYearId: tYear)),
      verify: (bloc) =>
          expect(bloc.state.catalogStatus, EnrollmentLoadStatus.failure),
    );
  });

  group('maille classe', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'une classe choisie borne le périmètre à son roster composé',
      setUp: () {
        stubEnrolled([
          student('s1'),
          student('s2'),
          student('s3'),
        ], inClassroom: false);
        stubPositions([ledger('s1'), ledger('s2'), ledger('s3')]);
        when(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) async => Right([member('s1'), member('s3')]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.map((r) => r.summary.student.id), ['s1', 's3']);
        expect(bloc.state.studentsInScope, 2);
        expect(bloc.state.classroomRosterSize, 2);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      '« Non affectés » : seuls les inscrits absents de TOUT roster de '
      'l\'année sont lus — un élève affecté ailleurs ne sort pas',
      setUp: () {
        stubEnrolled([
          student('s1'),
          student('s2'),
          student('s3'),
        ], inClassroom: false);
        stubPositions([ledger('s1'), ledger('s2'), ledger('s3')]);
        when(
          () => getClassrooms(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
          ),
        ).thenAnswer(
          (_) async => const Right([
            tClassroom,
            OfflineClassroom(
              id: 'cls-2',
              academicYearId: tYear,
              schoolLevelId: 'lvl-2',
              name: '2e A',
              totalCount: 0,
              femaleCount: 0,
              maleCount: 0,
            ),
          ]),
        );
        when(
          () => getComposedRosters(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: 'lvl-1',
          ),
        ).thenAnswer(
          (_) async => Right({
            'cls-1': [member('s1')],
          }),
        );
        when(
          () => getComposedRosters(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: 'lvl-2',
          ),
        ).thenAnswer(
          (_) async => Right({
            'cls-2': [member('s3', classroomId: 'cls-2')],
          }),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(classroomId: feeControlUnassigned),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.map((r) => r.summary.student.id), ['s2']);
        expect(bloc.state.studentsInScope, 1);
        // La rubrique n'a pas de roster : aucune taille annoncée.
        expect(bloc.state.classroomRosterSize, isNull);
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
        stubEnrolled([student('s1')], inClassroom: false);
        when(
          () => getRoster(
            classroomId: any(named: 'classroomId'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));
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

  group('pagination', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'change de page sans relire la base',
      setUp: () {
        stubEnrolled(List.generate(12, (i) => student('s$i')));
        stubPositions(List.generate(12, (i) => ledger('s$i')));
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
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
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
        stubPositions([ledger('s1')]);
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

  group('sélection de frais', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'plusieurs frais : une seule ligne par élève, attendu cumulé',
      setUp: () {
        stubEnrolled([student('s1')]);
        stubPositions([
          ledger('s1', expected: 100000, mirror: 100000),
          ledger('s1', feeCode: tOtherFee, expected: 35000),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(feeCodes: const [tFeeCode, tOtherFee]),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.rows.length, 1);
        final row = bloc.state.rows.single;
        expect(row.expected.entries.single.amountInCents, 135000);
        expect(row.paid.entries.single.amountInCents, 100000);
        // Soldé sur l'un, rien sur l'autre : partiel sur la sélection.
        expect(row.status, StudentChargeStatus.partial);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'deux niveaux pour le même élève fusionnent en UNE ligne',
      setUp: () {
        stubEnrolled([student('s1')]);
        stubPositions([
          ledger('s1', expected: 100000, schoolLevelId: 'lvl-1'),
          ledger('s1', expected: 60000, schoolLevelId: 'lvl-2'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        // Le tableau de bord compterait deux couples (élève, niveau) ; la liste
        // d'appel, elle, ne peut pas nommer deux fois le même enfant.
        expect(bloc.state.rows.length, 1);
        expect(
          bloc.state.rows.single.expected.entries.single.amountInCents,
          160000,
        );
      },
    );
  });

  group('situation « a payé au moins… »', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'ne garde que ceux qui ont franchi le plancher',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([
          ledger('s1', mirror: 60000),
          ledger('s2', mirror: 20000),
          ledger('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(
            filter: FeeControlPaymentFilter.threshold,
            thresholdInCents: 50000,
          ),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.summary.student.id), ['s1']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'un plancher vide vise tout le monde plutôt que personne',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([ledger('s1', mirror: 60000), ledger('s2')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.threshold),
        ),
      ),
      verify: (bloc) => expect(bloc.state.rows.length, 2),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'trop-perçu croisé : payé BRUT ≥ seuil mais imputable < seuil ⇒ exclu ; '
      'soldé sous le seuil ⇒ inclus (vecteurs partagés)',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([
          // s1 : 400 versés sur 300 de scolarité, rien sur 100 de fournitures.
          // Brut 400, imputable 300.
          ledger('s1', expected: 30000, mirror: 40000),
          ledger('s1', feeCode: tOtherFee, expected: 10000),
          // s2 : 50 $ dus et payés — soldé, il ne doit plus rien.
          ledger('s2', expected: 5000, mirror: 5000),
          // s3 : 350 imputables sur 400.
          ledger('s3', expected: 40000, mirror: 35000),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(
            feeCodes: const [tFeeCode, tOtherFee],
            filter: FeeControlPaymentFilter.threshold,
            thresholdInCents: 35000,
          ),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.studentId).toSet(), {'s2', 's3'}),
    );
  });

  group('classe mixte', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'deux devises PRÉSENTES : « au moins » indisponible, tri par situation '
      '(rien payé, partiel, soldé) sans conversion',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([
          // s1 soldé en dollars.
          ledger('s1', mirror: 100000),
          // s2 partiel : un peu de francs, rien en dollars.
          ledger('s2', feeCode: tOtherFee, currency: 'CDF', mirror: 100),
          ledger('s2'),
          // s3 rien payé.
          ledger('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(feeCodes: const [tFeeCode, tOtherFee]),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.currencies, {'USD', 'CDF'});
        expect(bloc.state.atLeastAvailable, isFalse);
        expect(bloc.state.soleCurrency, isNull);
        expect(bloc.state.rows.map((r) => r.studentId), ['s3', 's2', 's1']);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'une seule devise présente : « au moins » offert dans cette devise',
      setUp: () {
        stubEnrolled([student('s1')]);
        stubPositions([ledger('s1', currency: 'CDF')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) {
        expect(bloc.state.atLeastAvailable, isTrue);
        expect(bloc.state.soleCurrency, 'CDF');
      },
    );
  });

  group('ordre et compteurs', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'les lignes sortent du moins avancé au plus avancé',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([
          ledger('s1', mirror: 100000), // 100 %
          ledger('s2', mirror: 30000), // 30 %
          ledger('s3'), // 0 %
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(academicYearId: tYear, request: request()),
      ),
      verify: (bloc) =>
          expect(bloc.state.rows.map((r) => r.studentId), ['s3', 's2', 's1']),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'l\'encaissé porte sur la classe entière, jamais sur le filtre',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 40000),
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
        expect(bloc.state.rows.length, 1);
        expect(bloc.state.collected.entries.single.amountInCents, 140000);
        expect(bloc.state.expected.entries.single.amountInCents, 200000);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'deux devises : deux entrées, jamais une somme',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', feeCode: tOtherFee, currency: 'CDF', mirror: 900000),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(feeCodes: const [tFeeCode, tOtherFee]),
        ),
      ),
      verify: (bloc) => expect(bloc.state.collected.entries.length, 2),
    );
  });

  group('la situation change sans relire', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'une tuile recoupe la population déjà lue',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([
          ledger('s1', mirror: 100000),
          ledger('s2', mirror: 30000),
          ledger('s3'),
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(academicYearId: tYear, request: request()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const FeeControlSituationRequested(FeeControlPaymentFilter.none),
        );
      },
      verify: (bloc) {
        expect(bloc.state.rows.map((r) => r.studentId), ['s3']);
        // Les compteurs, eux, ne bougent pas : ils portent sur la classe.
        expect(bloc.state.breakdown.total, 3);
        // Une seule lecture du registre : recouper ne coûte rien.
        verify(
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
          ),
        ).called(1);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'la tuile OUBLIE le plancher : aucune n\'active « a payé au moins… »',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([ledger('s1', mirror: 60000), ledger('s2')]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(
            academicYearId: tYear,
            request: request(
              filter: FeeControlPaymentFilter.threshold,
              thresholdInCents: 50000,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const FeeControlSituationRequested(FeeControlPaymentFilter.all),
        );
      },
      verify: (bloc) {
        expect(bloc.state.rows.length, 2);
        expect(bloc.state.lastQuery?.threshold, isNull);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'sans recherche aboutie, la tuile ne fait rien',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FeeControlSituationRequested(FeeControlPaymentFilter.none),
      ),
      expect: () => const <FeeControlState>[],
    );
  });

  // ── Le seuil voyage en centimes ; sa devise vient des lignes lues (B1-B3) ──
  group('devise du plancher résolue sur les lignes lues', () {
    blocTest<FeeControlBloc, FeeControlState>(
      'B1 — le plancher prend la devise de la classe LUE (francs), sans '
      'qu\'aucune devise ne soit connue au départ',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', currency: 'CDF', mirror: 60000),
          ledger('s2', currency: 'CDF', mirror: 20000),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(
            filter: FeeControlPaymentFilter.threshold,
            thresholdInCents: 50000,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.lastQuery?.threshold, const Money(50000, 'CDF'));
        expect(bloc.state.lastQuery?.thresholdInCents, 50000);
        expect(bloc.state.rows.map((r) => r.studentId), ['s1']);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'B2 — classe en dollars puis classe en francs : le plancher suit la '
      'NOUVELLE classe, jamais la devise de la précédente',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubPositions([ledger('s1', mirror: 60000)]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(
            academicYearId: tYear,
            request: request(
              filter: FeeControlPaymentFilter.threshold,
              thresholdInCents: 50000,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        // La classe suivante est en francs : un partiel au-dessus du seuil,
        // un partiel au-dessous, un soldé.
        stubPositions([
          ledger('s1', currency: 'CDF', expected: 200000, mirror: 60000),
          ledger('s2', currency: 'CDF', expected: 200000, mirror: 20000),
          ledger('s3', currency: 'CDF', expected: 200000, mirror: 200000),
        ]);
        bloc.add(
          FeeControlSearchRequested(
            academicYearId: tYear,
            request: request(
              classroomId: 'cls-2',
              filter: FeeControlPaymentFilter.threshold,
              thresholdInCents: 50000,
            ),
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.lastQuery?.threshold, const Money(50000, 'CDF'));
        // Un seuil en dollars sur des lignes en francs ne retenait que les
        // soldés ; le partiel au-dessus du seuil est bien là.
        expect(bloc.state.rows.map((r) => r.studentId).toSet(), {'s1', 's3'});
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'B3 — champ vide sous « a payé au moins… » : le plancher vaut 0 dans la '
      'devise lue (R3), et part ainsi à l\'export',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([ledger('s1', mirror: 60000), ledger('s2')]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(filter: FeeControlPaymentFilter.threshold),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.lastQuery?.threshold, const Money(0, 'USD'));
        expect(bloc.state.rows.length, 2);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'en sélection mixte, aucun plancher n\'est résolu',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', mirror: 60000),
          ledger('s2', feeCode: tOtherFee, currency: 'CDF'),
        ]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FeeControlSearchRequested(
          academicYearId: tYear,
          request: request(
            feeCodes: const [tFeeCode, tOtherFee],
            filter: FeeControlPaymentFilter.threshold,
            thresholdInCents: 50000,
          ),
        ),
      ),
      verify: (bloc) => expect(bloc.state.lastQuery?.threshold, isNull),
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'le montant tapé après la lecture se résout sur la devise des lignes '
      'déjà lues',
      setUp: () {
        stubEnrolled([student('s1'), student('s2')]);
        stubPositions([
          ledger('s1', currency: 'CDF', mirror: 60000),
          ledger('s2', currency: 'CDF', mirror: 20000),
        ]);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(academicYearId: tYear, request: request()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const FeeControlSituationRequested(
            FeeControlPaymentFilter.threshold,
            thresholdInCents: 50000,
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.lastQuery?.threshold, const Money(50000, 'CDF'));
        expect(bloc.state.rows.map((r) => r.studentId), ['s1']);
      },
    );
  });

  // ── M14 : une situation demandée pendant un chargement n'est pas perdue ───
  group('situation demandée pendant un chargement', () {
    late Completer<Either<Failure, List<LocalRecoveryLine>>> gate;

    void stubSlowPositions(List<LocalRecoveryLine> lines) {
      gate = Completer();
      when(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: any(named: 'feeCodes'),
        ),
      ).thenAnswer((_) => gate.future);
    }

    final lines = [
      ledger('s1', mirror: 60000),
      ledger('s2', mirror: 20000),
      ledger('s3'),
    ];

    blocTest<FeeControlBloc, FeeControlState>(
      'M14 — le montant tapé avant l\'arrivée des lignes s\'y applique',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubSlowPositions(lines);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(academicYearId: tYear, request: request()),
        );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, EnrollmentLoadStatus.loading);
        bloc.add(
          const FeeControlSituationRequested(
            FeeControlPaymentFilter.threshold,
            thresholdInCents: 50000,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        gate.complete(Right(lines));
      },
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.success);
        expect(
          bloc.state.lastQuery?.statusFilter,
          FeeControlPaymentFilter.threshold,
        );
        expect(bloc.state.lastQuery?.threshold, const Money(50000, 'USD'));
        expect(bloc.state.rows.map((r) => r.studentId), ['s1']);
      },
    );

    blocTest<FeeControlBloc, FeeControlState>(
      'une nouvelle recherche efface la situation en attente : elle porte '
      'déjà la question entière',
      setUp: () {
        stubEnrolled([student('s1'), student('s2'), student('s3')]);
        stubSlowPositions(lines);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          FeeControlSearchRequested(academicYearId: tYear, request: request()),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const FeeControlSituationRequested(FeeControlPaymentFilter.none),
        );
        bloc.add(
          FeeControlSearchRequested(
            academicYearId: tYear,
            request: request(filter: FeeControlPaymentFilter.settled),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        gate.complete(Right(lines));
      },
      verify: (bloc) {
        expect(
          bloc.state.lastQuery?.statusFilter,
          FeeControlPaymentFilter.settled,
        );
      },
    );
  });
}
