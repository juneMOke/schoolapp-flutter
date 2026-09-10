import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_codes_for_year_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_recovery_positions_use_case.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';

class MockGetFeeCodes extends Mock implements GetFeeCodesForYearUseCase {}

class MockGetPositions extends Mock implements GetRecoveryPositionsUseCase {}

class MockGetClassrooms extends Mock implements GetOfflineClassroomsUseCase {}

class MockGetRosters extends Mock implements GetComposedRostersUseCase {}

class MockSearchEnrollments extends Mock
    implements SearchLocalEnrollmentsUseCase {}

LocalRecoveryLine line(
  String studentId, {
  String? level = 'lvl-1',
  int expected = 30000,
  int paid = 0,
}) => LocalRecoveryLine(
  schoolLevelId: level,
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: 'TUITION',
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
  late MockGetFeeCodes getFeeCodes;
  late MockGetPositions getPositions;

  late MockGetClassrooms getClassrooms;
  late MockGetRosters getRosters;
  late MockSearchEnrollments searchEnrollments;

  RecouvrementDashboardBloc build() => RecouvrementDashboardBloc(
    getFeeCodes: getFeeCodes,
    getPositions: getPositions,
    getClassrooms: getClassrooms,
    getRosters: getRosters,
    searchEnrollments: searchEnrollments,
  );

  setUp(() {
    getFeeCodes = MockGetFeeCodes();
    getPositions = MockGetPositions();
    getClassrooms = MockGetClassrooms();
    getRosters = MockGetRosters();
    searchEnrollments = MockSearchEnrollments();
    // Le comptage des non-facturés est best-effort : sans stub il échouerait,
    // et c'est précisément ce que le bloc doit savoir absorber sans tomber.
    when(
      () => searchEnrollments.currentYearEnrolled(
        academicYearId: any(named: 'academicYearId'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('non lu')));
  });

  void stubPositions(List<LocalRecoveryLine> lines) {
    when(
      () => getPositions(
        academicYearId: any(named: 'academicYearId'),
        feeCodes: any(named: 'feeCodes'),
        schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
      ),
    ).thenAnswer((_) async => Right(lines));
  }

  group('les natures de frais', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'succès : la liste alimente la sélection',
      setUp: () => when(
        () => getFeeCodes(academicYearId: any(named: 'academicYearId')),
      ).thenAnswer((_) async => const Right(['TUITION', 'BOOKS'])),
      build: build,
      act: (bloc) =>
          bloc.add(const RecouvrementFeeCodesRequested(academicYearId: 'ay-1')),
      expect: () => [
        isA<RecouvrementDashboardState>().having(
          (s) => s.feeCodesStatus,
          'status',
          EnrollmentLoadStatus.loading,
        ),
        isA<RecouvrementDashboardState>()
            .having(
              (s) => s.feeCodesStatus,
              'status',
              EnrollmentLoadStatus.success,
            )
            .having((s) => s.feeCodes, 'codes', ['TUITION', 'BOOKS']),
      ],
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'échec : le type ET le message sont portés, pour que la reprise parle',
      setUp: () => when(
        () => getFeeCodes(academicYearId: any(named: 'academicYearId')),
      ).thenAnswer((_) async => const Left(StorageFailure('base illisible'))),
      build: build,
      act: (bloc) =>
          bloc.add(const RecouvrementFeeCodesRequested(academicYearId: 'ay-1')),
      skip: 1,
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having(
              (s) => s.feeCodesStatus,
              'status',
              EnrollmentLoadStatus.failure,
            )
            .having((s) => s.errorType, 'type', EnrollmentErrorType.server)
            .having((s) => s.errorMessage, 'message', 'base illisible'),
      ],
    );
  });

  group('la lecture du registre', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'succès : les chiffres sont projetés et la requête retenue',
      setUp: () => stubPositions([line('s1'), line('s2', paid: 30000)]),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
        ),
      ),
      skip: 1,
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having((s) => s.status, 'status', EnrollmentLoadStatus.success)
            .having((s) => s.figures.total, 'total', 2)
            .having((s) => s.figures.none, 'rien', 1)
            .having((s) => s.figures.settled, 'soldés', 1)
            .having((s) => s.lastQuery?.feeCodes, 'sélection', ['TUITION']),
      ],
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'échec : les chiffres RETOMBENT à vide plutôt que de rester périmés',
      setUp: () {
        when(
          () => getPositions(
            academicYearId: any(named: 'academicYearId'),
            feeCodes: any(named: 'feeCodes'),
            schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('boum')));
      },
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
        ),
      ),
      skip: 1,
      expect: () => [
        isA<RecouvrementDashboardState>()
            .having((s) => s.status, 'status', EnrollmentLoadStatus.failure)
            .having((s) => s.figures, 'chiffres', RecouvrementKeyFigures.empty)
            .having((s) => s.errorType, 'type', EnrollmentErrorType.server),
      ],
      verify: (bloc) => expect(
        bloc.lines,
        isEmpty,
        reason: 'les lignes hors état suivent les chiffres',
      ),
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'une sélection VIDE n\'interroge rien et n\'émet rien',
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(academicYearId: 'ay-1', feeCodes: []),
      ),
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
      'un cycle vide vaut « toute l\'école », jamais une clause qui ne filtre rien',
      setUp: () => stubPositions([line('s1')]),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
          schoolLevelGroupId: '',
        ),
      ),
      verify: (_) => verify(
        () => getPositions(
          academicYearId: 'ay-1',
          feeCodes: const ['TUITION'],
          schoolLevelGroupId: null,
        ),
      ).called(1),
    );

    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'la sélection est normalisée : même requête quel que soit l\'ordre',
      setUp: () => stubPositions([line('s1')]),
      build: build,
      act: (bloc) => bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION', 'BOOKS', 'TUITION'],
        ),
      ),
      verify: (_) => verify(
        () => getPositions(
          academicYearId: 'ay-1',
          feeCodes: const ['BOOKS', 'TUITION'],
          schoolLevelGroupId: null,
        ),
      ).called(1),
    );
  });

  group('la reprise', () {
    blocTest<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      'sans lecture précédente, « réessayer » ne fait RIEN',
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
      'rejoue EXACTEMENT la lecture qui a échoué, pas une autre',
      setUp: () => stubPositions([line('s1')]),
      build: build,
      act: (bloc) async {
        bloc.add(
          const RecouvrementRequested(
            academicYearId: 'ay-1',
            feeCodes: ['BOOKS'],
            schoolLevelGroupId: 'grp-2',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RecouvrementRefreshRequested());
      },
      verify: (_) => verify(
        () => getPositions(
          academicYearId: 'ay-1',
          feeCodes: const ['BOOKS'],
          schoolLevelGroupId: 'grp-2',
        ),
      ).called(2),
    );
  });

  group('les lectures concurrentes', () {
    test('seule la PLUS RÉCENTE écrit — sinon un écran porterait une autre '
        'sélection sous le nom de celle qu\'il affiche', () async {
      final slow = Completer<Either<Failure, List<LocalRecoveryLine>>>();
      final fast = Completer<Either<Failure, List<LocalRecoveryLine>>>();

      when(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: const ['TUITION'],
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer((_) => slow.future);
      when(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: const ['BOOKS'],
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer((_) => fast.future);

      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['BOOKS'],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // La seconde répond d'abord, la première ensuite : la périmée ne doit
      // rien écrire.
      fast.complete(Right([line('s-books')]));
      await Future<void>.delayed(Duration.zero);
      slow.complete(Right([line('s1'), line('s2'), line('s3')]));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.lastQuery?.feeCodes, ['BOOKS']);
      expect(bloc.state.figures.total, 1);
      expect(bloc.lines.single.studentId, 's-books');
    });
  });

  group('le numéro de lecture', () {
    test('il change à chaque lecture, y compris sur un échec', () async {
      stubPositions([line('s1')]);
      final bloc = build();
      addTearDown(bloc.close);

      expect(bloc.state.snapshotId, 0);

      bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final first = bloc.state.snapshotId;
      expect(first, greaterThan(0));

      when(
        () => getPositions(
          academicYearId: any(named: 'academicYearId'),
          feeCodes: any(named: 'feeCodes'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('boum')));

      bloc.add(
        const RecouvrementRequested(
          academicYearId: 'ay-1',
          feeCodes: ['TUITION'],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        bloc.state.snapshotId,
        greaterThan(first),
        reason:
            'les lignes hors état ont changé, les consommateurs doivent le '
            'savoir même quand elles sont retombées à vide',
      );
    });
  });
}
