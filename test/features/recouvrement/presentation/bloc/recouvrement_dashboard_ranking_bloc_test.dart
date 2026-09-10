import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_list_item.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_codes_for_year_use_case.dart';

class MockGetFeeCodesForYearUseCase extends Mock
    implements GetFeeCodesForYearUseCase {}

class MockGetRecoveryPositions extends Mock
    implements GetRecoveryPositionsUseCase {}

class MockGetOfflineClassroomsUseCase extends Mock
    implements GetOfflineClassroomsUseCase {}

class MockGetComposedRostersUseCase extends Mock
    implements GetComposedRostersUseCase {}

class MockSearchLocalEnrollmentsUseCase extends Mock
    implements SearchLocalEnrollmentsUseCase {}

LocalEnrollmentListItem enrolled(String studentId) => LocalEnrollmentListItem(
  enrollmentId: 'e-$studentId',
  studentId: studentId,
  firstName: 'P',
  lastName: 'N',
  dateOfBirth: '2010-01-01',
  gender: OfflineGender.male,
  enrollmentType: EnrollmentType.newEnrollment,
  status: OfflineEnrollmentStatus.completed,
  enrollmentDate: '2026-09-01',
  syncState: SyncState.synced,
);

OfflineClassroom classroom(String id, String name, {String level = 'lvl-1'}) =>
    OfflineClassroom(
      id: id,
      academicYearId: tYear,
      schoolLevelId: level,
      name: name,
      totalCount: 0,
      femaleCount: 0,
      maleCount: 0,
    );

ClassroomMember member(String studentId, String classroomId) => ClassroomMember(
  id: 'm-$studentId',
  studentId: studentId,
  classroomId: classroomId,
  academicYearId: tYear,
  studentFirstName: 'P',
  studentLastName: 'N',
  studentGender: ClassroomMemberGender.male,
);

const tYear = 'ay-1';
const tFeeCode = 'TUITION';
const tGroup = 'grp-1';

LocalRecoveryLine at(
  String studentId, {
  String? level = 'lvl-1',
  int expected = 100000,
  int paid = 0,
}) => LocalRecoveryLine(
  schoolLevelId: level,
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: tFeeCode,
      position: FeeChargePosition(
        currency: 'USD',
        expectedInCents: expected,
        paidMirrorInCents: paid,
        paidPendingInCents: 0,
      ),
    ),
  ],
);

void main() {
  late MockGetFeeCodesForYearUseCase getFeeCodes;
  late MockGetRecoveryPositions getPositions;
  late MockGetOfflineClassroomsUseCase getClassrooms;
  late MockGetComposedRostersUseCase getRosters;
  late MockSearchLocalEnrollmentsUseCase searchEnrollments;

  RecouvrementDashboardBloc build() => RecouvrementDashboardBloc(
    getFeeCodes: getFeeCodes,
    getPositions: getPositions,
    getClassrooms: getClassrooms,
    getRosters: getRosters,
    searchEnrollments: searchEnrollments,
  );

  void stubEnrolled(Either<Failure, List<LocalEnrollmentListItem>> outcome) {
    when(
      () => searchEnrollments.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer((_) async => outcome);
  }

  setUp(() {
    getFeeCodes = MockGetFeeCodesForYearUseCase();
    getPositions = MockGetRecoveryPositions();
    getClassrooms = MockGetOfflineClassroomsUseCase();
    getRosters = MockGetComposedRostersUseCase();
    searchEnrollments = MockSearchLocalEnrollmentsUseCase();
    // Par défaut, la lecture complémentaire ne trouve personne : les cas qui
    // s'y intéressent la re-stubbent.
    stubEnrolled(const Right(<LocalEnrollmentListItem>[]));
  });

  void stubClasses({
    List<OfflineClassroom> classrooms = const <OfflineClassroom>[],
    Map<String, List<ClassroomMember>> rosters =
        const <String, List<ClassroomMember>>{},
  }) {
    when(
      () => getClassrooms(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
      ),
    ).thenAnswer((_) async => Right(classrooms));
    when(
      () => getRosters(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelId: any(named: 'schoolLevelId'),
      ),
    ).thenAnswer((_) async => Right(rosters));
  }

  void stubFeeCodes(Either<Failure, List<String>> outcome) {
    when(
      () => getFeeCodes(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => outcome);
  }

  void stubPositions(Either<Failure, List<LocalRecoveryLine>> outcome) {
    when(
      () => getPositions(
        academicYearId: any(named: 'academicYearId'),
        feeCodes: any(named: 'feeCodes'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer((_) async => outcome);
  }

  group('natures de frais', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'chargement puis liste, telle que le grand-livre la rend',
      setUp: () => stubFeeCodes(const Right(['CANTINE', 'TUITION'])),
      build: build,
      act: (bloc) =>
          bloc.add(const RecouvrementFeeCodesRequested(academicYearId: tYear)),
      expect: () => [
        isA<RecouvrementDashboardState>().having(
          (s) => s.feeCodesStatus,
          'feeCodesStatus',
          EnrollmentLoadStatus.loading,
        ),
        isA<RecouvrementDashboardState>()
            .having(
              (s) => s.feeCodesStatus,
              'feeCodesStatus',
              EnrollmentLoadStatus.success,
            )
            .having((s) => s.feeCodes, 'feeCodes', ['CANTINE', 'TUITION']),
      ],
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'un échec de lecture locale se dit « serveur », jamais réseau ni 403',
      setUp: () => stubFeeCodes(const Left(StorageFailure('bases fermée'))),
      build: build,
      act: (bloc) =>
          bloc.add(const RecouvrementFeeCodesRequested(academicYearId: tYear)),
      skip: 1,
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having(
              (s) => s.feeCodesStatus,
              'feeCodesStatus',
              EnrollmentLoadStatus.failure,
            )
            .having(
              (s) => s.errorType,
              'errorType',
              EnrollmentErrorType.server,
            ),
      ],
    );
  });

  group('position de la population', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'projette le classement et retient de quoi il est le résultat',
      setUp: () => stubPositions(
        Right([
          at('s1', paid: 100000),
          at('s2'),
          at('s3', level: 'lvl-2', paid: 100000),
        ]),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
          schoolLevelGroupId: tGroup,
        ),
      ),
      skip: 1,
      // Deux états après le chargement : le classement, puis le compteur de
      // non-facturés que la lecture complémentaire ajoute (FCD-5). Seul le
      // premier est décrit ici.
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having((s) => s.status, 'status', EnrollmentLoadStatus.success)
            .having((s) => s.ranking.total.total, 'concernés', 3)
            .having((s) => s.ranking.total.settled, 'soldés', 2)
            // Le plus en retard en tête : lvl-1 est à 50 %, lvl-2 à 100 %.
            .having(
              (s) => s.ranking.groups.map((g) => g.schoolLevelId),
              'groupes classés',
              ['lvl-1', 'lvl-2'],
            )
            .having(
              (s) => s.lastQuery,
              'lastQuery',
              const RecouvrementQuery(
                academicYearId: tYear,
                feeCodes: [tFeeCode],
                schoolLevelGroupId: tGroup,
              ),
            ),
        isA<RecouvrementDashboardState>().having(
          (s) => s.unbilled,
          'non-facturés',
          0,
        ),
      ],
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'aucun élève concerné : succès à résumé vide, distinct de l\'écran vierge',
      setUp: () => stubPositions(const Right(<LocalRecoveryLine>[])),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
        ),
      ),
      skip: 1,
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having((s) => s.status, 'status', EnrollmentLoadStatus.success)
            .having((s) => s.hasEmptyResult, 'hasEmptyResult', isTrue)
            .having((s) => s.lastQuery, 'lastQuery', isNotNull),
        isA<RecouvrementDashboardState>().having(
          (s) => s.unbilled,
          'non-facturés',
          0,
        ),
      ],
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'un cycle vide ou blanc ne descend PAS jusqu\'au SQL',
      setUp: () => stubPositions(const Right(<LocalRecoveryLine>[])),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
          schoolLevelGroupId: '   ',
        ),
      ),
      verify: (_) {
        verify(
          () => getPositions(
            academicYearId: tYear,
            feeCodes: const [tFeeCode],
            schoolLevelGroupId: null,
          ),
        ).called(1);
      },
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'un échec EFFACE le classement précédent — le laisser à côté du message '
      'le ferait passer pour valide sous les critères affichés',
      setUp: () {
        when(
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((invocation) async {
          final fees = invocation.namedArguments[#feeCodes] as List<String>;
          return fees.contains(tFeeCode)
              ? Right([at('s1', paid: 100000)])
              : const Left(StorageFailure('base fermée'));
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(
          const RecouvrementRequested(
            academicYearId: tYear,
            feeCodes: [tFeeCode],
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const RecouvrementRequested(
            academicYearId: tYear,
            feeCodes: ['CANTINE'],
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.status, EnrollmentLoadStatus.failure);
        expect(bloc.state.ranking, RecouvrementRankingSummary.empty);
        expect(bloc.state.lastQuery?.feeCodes, ['CANTINE']);
      },
    );
  });

  group('reprise', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'sans lecture antérieure, réessayer ne fait RIEN — une reprise ne doit '
      'pas interroger autre chose que ce qui a échoué',
      build: build,
      act: (bloc) => bloc.add(const RecouvrementRefreshRequested()),
      expect: () => const <RecouvrementDashboardState>[],
      verify: (_) => verifyNever(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: any(named: 'feeCodes'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ),
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'rejoue EXACTEMENT la dernière lecture, cycle compris',
      setUp: () => stubPositions(const Right(<LocalRecoveryLine>[])),
      build: build,
      act: (bloc) async {
        bloc.add(
          const RecouvrementRequested(
            academicYearId: tYear,
            feeCodes: [tFeeCode],
            schoolLevelGroupId: tGroup,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RecouvrementRefreshRequested());
      },
      verify: (_) {
        verify(
          () => getPositions(
            academicYearId: tYear,
            feeCodes: const [tFeeCode],
            schoolLevelGroupId: tGroup,
          ),
        ).called(2);
      },
    );
  });

  group('résultats périmés', () {
    test('une lecture doublée puis résolue EN DERNIER ne repeint pas le '
        'classement de la plus récente', () async {
      final first = Completer<Either<Failure, List<LocalRecoveryLine>>>();
      final second = Completer<Either<Failure, List<LocalRecoveryLine>>>();
      when(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: any(named: 'feeCodes'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer((invocation) {
        final fees = invocation.namedArguments[#feeCodes] as List<String>;
        return fees.contains(tFeeCode) ? first.future : second.future;
      });

      final bloc = build();
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: ['CANTINE'],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // La SECONDE aboutit d'abord…
      second.complete(Right([at('s-cantine', paid: 100000)]));
      await Future<void>.delayed(Duration.zero);
      // …puis la première, périmée, rend une population toute différente.
      first.complete(Right([at('s-a'), at('s-b'), at('s-c')]));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.lastQuery?.feeCodes, ['CANTINE']);
      expect(bloc.state.ranking.total.total, 1);
      expect(bloc.state.ranking.total.settled, 1);

      await bloc.close();
    });
  });

  group('mapping des échecs', () {
    for (final (failure, expected) in <(Failure, EnrollmentErrorType)>[
      (const NetworkFailure('coupure'), EnrollmentErrorType.network),
      (const StorageFailure('base fermée'), EnrollmentErrorType.server),
      (const ServerFailure('inattendu'), EnrollmentErrorType.unknown),
    ]) {
      blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
        '${failure.runtimeType} → $expected',
        setUp: () => stubPositions(Left(failure)),
        build: build,
        act: (bloc) => bloc.add(
          const RecouvrementRequested(
            academicYearId: tYear,
            feeCodes: [tFeeCode],
          ),
        ),
        skip: 1,
        expect: () => [
          isA<RecouvrementDashboardState>()
              .having((s) => s.errorType, 'errorType', expected)
              .having((s) => s.errorMessage, 'errorMessage', failure.message),
        ],
      );
    }
  });

  group('dépliage en classes', () {
    Future<RecouvrementDashboardBloc> loaded(
      List<LocalRecoveryLine> positions,
    ) async {
      stubPositions(Right(positions));
      final bloc = build();
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      return bloc;
    }

    test(
      'répartit les élèves DÉJÀ chargés, sans relire le grand-livre',
      () async {
        stubClasses(
          classrooms: [classroom('c-a', '6e A'), classroom('c-b', '6e B')],
          rosters: {
            'c-a': [member('s1', 'c-a'), member('s2', 'c-a')],
            'c-b': [member('s3', 'c-b')],
          },
        );
        final bloc = await loaded([
          at('s1', paid: 100000),
          at('s2'),
          at('s3', paid: 100000),
        ]);

        bloc.add(
          const RecouvrementGroupToggled(
            academicYearId: tYear,
            schoolLevelId: 'lvl-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.expandedLevelId, 'lvl-1');
        expect(bloc.state.classes.map((c) => c.name), ['6e A', '6e B']);
        expect(bloc.state.classes.first.breakdown.settled, 1);
        expect(bloc.state.classes.first.breakdown.none, 1);
        // Une seule lecture des positions : celle de l'interrogation initiale.
        verify(
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).called(1);

        await bloc.close();
      },
    );

    test(
      'les élèves qu\'aucune classe ne réclame forment une ligne FINALE — '
      'sans elle, la somme des classes serait inférieure au niveau',
      () async {
        stubClasses(
          classrooms: [classroom('c-a', '6e A')],
          rosters: {
            'c-a': [member('s1', 'c-a')],
          },
        );
        final bloc = await loaded([at('s1', paid: 100000), at('s-orphelin')]);

        bloc.add(
          const RecouvrementGroupToggled(
            academicYearId: tYear,
            schoolLevelId: 'lvl-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final rows = bloc.state.classes;
        expect(rows.length, 2);
        expect(rows.last.isUnassigned, isTrue);
        expect(rows.last.breakdown.total, 1);
        expect(
          rows.fold(0, (sum, r) => sum + r.breakdown.total),
          bloc.state.ranking.total.total,
        );

        await bloc.close();
      },
    );

    test('ne déplie QUE le niveau demandé', () async {
      stubClasses(
        classrooms: [classroom('c-a', '6e A')],
        rosters: {
          'c-a': [member('s1', 'c-a')],
        },
      );
      final bloc = await loaded([
        at('s1', paid: 100000),
        at('s9', level: 'lvl-2'),
      ]);

      bloc.add(
        const RecouvrementGroupToggled(
          academicYearId: tYear,
          schoolLevelId: 'lvl-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // `s9` est d'un autre niveau : il ne doit apparaître nulle part ici, pas
      // même parmi les non-répartis.
      expect(
        bloc.state.classes.fold(0, (sum, r) => sum + r.breakdown.total),
        1,
      );

      await bloc.close();
    });

    test('re-cliquer REPLIE, et n\'attend rien', () async {
      stubClasses(
        classrooms: [classroom('c-a', '6e A')],
        rosters: {
          'c-a': [member('s1', 'c-a')],
        },
      );
      final bloc = await loaded([at('s1')]);

      const toggle = RecouvrementGroupToggled(
        academicYearId: tYear,
        schoolLevelId: 'lvl-1',
      );
      bloc.add(toggle);
      await Future<void>.delayed(Duration.zero);
      bloc.add(toggle);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.expandedLevelId, isNull);
      expect(bloc.state.classes, isEmpty);

      await bloc.close();
    });

    test('le groupe « niveau non renseigné » ne se déplie pas : il n\'y a pas '
        'de classe où chercher', () async {
      stubClasses();
      final bloc = await loaded([at('s1', level: null)]);

      bloc.add(
        const RecouvrementGroupToggled(
          academicYearId: tYear,
          schoolLevelId: null,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.expandedLevelId, isNull);
      verifyNever(
        () => getClassrooms(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
        ),
      );

      await bloc.close();
    });

    test(
      'aucune classe au référentiel : le fait est REMONTÉ, à charge du rendu '
      'de dire laquelle des deux causes',
      () async {
        stubClasses();
        final bloc = await loaded([at('s1')]);

        bloc.add(
          const RecouvrementGroupToggled(
            academicYearId: tYear,
            schoolLevelId: 'lvl-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.classroomsMissing, isTrue);
        expect(bloc.state.classesStatus, EnrollmentLoadStatus.success);

        await bloc.close();
      },
    );

    test('une nouvelle interrogation REPLIE : les classes ouvertes étaient '
        'celles d\'un autre frais', () async {
      stubClasses(
        classrooms: [classroom('c-a', '6e A')],
        rosters: {
          'c-a': [member('s1', 'c-a')],
        },
      );
      final bloc = await loaded([at('s1')]);

      bloc.add(
        const RecouvrementGroupToggled(
          academicYearId: tYear,
          schoolLevelId: 'lvl-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.expandedLevelId, 'lvl-1');

      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: ['CANTINE'],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.expandedLevelId, isNull);
      expect(bloc.state.classes, isEmpty);

      await bloc.close();
    });
  });

  group('les non-facturés', () {
    Future<RecouvrementDashboardBloc> run() async {
      final bloc = build();
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
          schoolLevelGroupId: tGroup,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      return bloc;
    }

    test(
      'compte les inscrits qu\'aucune créance de ce frais ne concerne',
      () async {
        stubPositions(Right([at('s1', paid: 100000), at('s2')]));
        stubEnrolled(
          Right([
            enrolled('s1'),
            enrolled('s2'),
            enrolled('s3'),
            enrolled('s4'),
          ]),
        );

        final bloc = await run();

        expect(bloc.state.unbilled, 2);
        // Et surtout : le TAUX les ignore. Deux concernés, un soldé → 50 %.
        expect(bloc.state.ranking.total.total, 2);
        expect(bloc.state.ranking.settledPercent, 50);

        await bloc.close();
      },
    );

    test('un élève à cheval sur deux niveaux ne compte qu\'UNE fois ici — le '
        'soustraire deux fois inventerait un non-facturé', () async {
      stubPositions(Right([at('s1', paid: 100000), at('s1', level: 'lvl-2')]));
      stubEnrolled(Right([enrolled('s1'), enrolled('s2')]));

      final bloc = await run();

      // Le classement compte 2 couples (D5) ; la soustraction, elle, porte sur
      // des élèves DISTINCTS : seul `s2` n'est pas facturé.
      expect(bloc.state.ranking.total.total, 2);
      expect(bloc.state.unbilled, 1);

      await bloc.close();
    });

    test('un élève qui porte DEUX dossiers sur l\'année ne compte qu\'une '
        'fois : la note dit des ÉLÈVES, pas des lignes', () async {
      // Une pré-inscription reprise, ou un brouillon local à côté du dossier
      // descendu : la recherche rend alors deux lignes pour le même élève.
      stubPositions(Right([at('s1', paid: 100000)]));
      stubEnrolled(Right([enrolled('s1'), enrolled('s2'), enrolled('s2')]));

      final bloc = await run();

      expect(bloc.state.unbilled, 1);

      await bloc.close();
    });

    test('la lecture complémentaire en échec N\'EMPORTE PAS l\'écran : le '
        'classement reste, le compteur reste inconnu', () async {
      stubPositions(Right([at('s1', paid: 100000)]));
      stubEnrolled(const Left(StorageFailure('base fermée')));

      final bloc = await run();

      expect(bloc.state.status, EnrollmentLoadStatus.success);
      expect(bloc.state.ranking.total.total, 1);
      // `null`, jamais `0` : « on n'a pas pu vérifier » n'est pas « personne ».
      expect(bloc.state.unbilled, isNull);

      await bloc.close();
    });

    test(
      'la lecture PRINCIPALE en échec ne lance même pas la complémentaire',
      () async {
        stubPositions(const Left(StorageFailure('base fermée')));

        final bloc = await run();

        expect(bloc.state.unbilled, isNull);
        verifyNever(
          () => searchEnrollments.currentYearEnrolled(
            academicYearId: any(named: 'academicYearId'),
            schoolLevelId: any(named: 'schoolLevelId'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'le périmètre de la note est celui de l\'écran : le cycle descend',
      () async {
        stubPositions(const Right(<LocalRecoveryLine>[]));

        final bloc = await run();

        verify(
          () => searchEnrollments.currentYearEnrolled(
            academicYearId: tYear,
            schoolLevelGroupId: tGroup,
          ),
        ).called(1);

        await bloc.close();
      },
    );
  });

  group('revue — courses', () {
    test('une nouvelle interrogation ANNULE le dépliage en vol : sa réponse '
        'décrirait les classes d\'un autre frais', () async {
      final rosters =
          Completer<Either<Failure, Map<String, List<ClassroomMember>>>>();
      when(
        () => getClassrooms(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
        ),
      ).thenAnswer((_) async => Right([classroom('c-a', '6e A')]));
      when(
        () => getRosters(
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
        ),
      ).thenAnswer((_) => rosters.future);
      stubPositions(Right([at('s1', paid: 100000)]));

      final bloc = build();
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: [tFeeCode],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const RecouvrementGroupToggled(
          academicYearId: tYear,
          schoolLevelId: 'lvl-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Le frais change pendant que les rosters volent encore.
      bloc.add(
        const RecouvrementRequested(
          academicYearId: tYear,
          feeCodes: ['CANTINE'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      rosters.complete(
        Right({
          'c-a': [member('s1', 'c-a')],
        }),
      );
      await Future<void>.delayed(Duration.zero);

      // La réponse périmée n'a rien écrit : l'état reste replié et propre.
      expect(bloc.state.expandedLevelId, isNull);
      expect(bloc.state.classes, isEmpty);
      expect(bloc.state.classesStatus, EnrollmentLoadStatus.initial);

      await bloc.close();
    });
  });
}
