import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';

import '../../../fixtures/recovery_fixtures.dart';

class _MockRepo extends Mock implements RecoveryDashboardRepository {}

class _MockCount extends Mock implements CountPendingPaymentsUseCase {}

void main() {
  late _MockRepo repo;
  late _MockCount count;
  const tuition = RecoveryQuestion(feeCodes: ['TUITION']);
  const atLeast = RecoveryQuestion(
    feeCodes: ['TUITION', 'REGISTRATION'],
    rule: RecoveryRuleKind.atLeast,
    thresholdInCents: 15000,
  );

  setUpAll(() => registerFallbackValue(tuition));
  setUp(() {
    repo = _MockRepo();
    count = _MockCount();
    when(() => count()).thenAnswer((_) async => const Right(2));
  });

  RecoveryDashboardCubit build() =>
      RecoveryDashboardCubit(repository: repo, countPending: count);

  blocTest<RecoveryDashboardCubit, RecoveryDashboardState>(
    'les encaissements en attente partent avec la question',
    build: build,
    setUp: () => when(
      () => repo.dashboard(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => Right(recoveryDashboardFixture())),
    act: (c) => c.ask('ay-1', tuition),
    verify: (_) => verify(
      () => repo.dashboard('ay-1', tuition, pendingWrites: 2),
    ).called(1),
    expect: () => [
      isA<RecoveryDashboardState>().having(
        (s) => s.status,
        'status',
        RecoveryLoadStatus.loading,
      ),
      isA<RecoveryDashboardState>()
          .having((s) => s.status, 'status', RecoveryLoadStatus.success)
          .having((s) => s.dashboard?.studentCount, 'studentCount', 478),
    ],
  );

  blocTest<RecoveryDashboardCubit, RecoveryDashboardState>(
    'R8 : « au moins » refusé en mixte retombe sur « a payé quelque chose »',
    build: build,
    setUp: () {
      when(
        () => repo.dashboard(
          any(),
          atLeast,
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ApiValidationFailure(
            code: ApiErrorCode.businessRule,
            detailCode: recoveryAtLeastUnavailable,
          ),
        ),
      );
      when(
        () => repo.dashboard(
          any(),
          atLeast.copyWith(rule: RecoveryRuleKind.somePayment),
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((_) async => Right(recoveryMixedDashboardFixture()));
    },
    act: (c) => c.ask('ay-1', atLeast),
    wait: const Duration(milliseconds: 10),
    skip: 2,
    expect: () => [
      isA<RecoveryDashboardState>()
          .having((s) => s.status, 'status', RecoveryLoadStatus.success)
          .having((s) => s.question?.rule, 'rule', RecoveryRuleKind.somePayment)
          // Le montant reste : il nourrit le compteur s'il redevient utile.
          .having((s) => s.question?.thresholdInCents, 'seuil', 15000),
    ],
  );

  blocTest<RecoveryDashboardCubit, RecoveryDashboardState>(
    'une relecture garde les chiffres à l\'écran ; un échec aussi',
    build: build,
    seed: () => RecoveryDashboardState(
      question: tuition,
      status: RecoveryLoadStatus.success,
      dashboard: recoveryDashboardFixture(),
    ),
    setUp: () => when(
      () => repo.dashboard(
        any(),
        any(),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure('x'))),
    act: (c) => c.ask('ay-1', tuition),
    expect: () => [
      isA<RecoveryDashboardState>().having(
        (s) => s.isRefreshing,
        'refreshing',
        isTrue,
      ),
      isA<RecoveryDashboardState>()
          .having((s) => s.status, 'status', RecoveryLoadStatus.failure)
          .having((s) => s.dashboard, 'dashboard', isNotNull),
    ],
  );

  test(
    'une réponse plus ancienne qu\'une question posée depuis est jetée',
    () async {
      final slow = <Future<void>>[];
      when(
        () => repo.dashboard(
          any(),
          tuition,
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return Right(recoveryMixedDashboardFixture());
      });
      when(
        () => repo.dashboard(
          any(),
          atLeast,
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((_) async => Right(recoveryDashboardFixture()));
      final cubit = build();
      slow.add(cubit.ask('ay-1', tuition));
      await cubit.ask('ay-1', atLeast);
      await Future.wait(slow);
      expect(cubit.state.question, atLeast);
      expect(cubit.state.dashboard?.isMixed, isFalse);
      await cubit.close();
    },
  );

  test(
    'une AUTRE question ne garde pas les chiffres de la précédente',
    () async {
      when(
        () => repo.dashboard(
          any(),
          tuition,
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((_) async => Right(recoveryDashboardFixture()));
      when(
        () => repo.dashboard(
          any(),
          atLeast,
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure('x')));
      final cubit = build();
      await cubit.ask('ay-1', tuition);
      expect(cubit.state.dashboard, isNotNull);
      await cubit.ask('ay-1', atLeast);
      expect(cubit.state.status, RecoveryLoadStatus.failure);
      expect(cubit.state.dashboard, isNull);
      await cubit.close();
    },
  );

  test('un périmètre que l\'année ne connaît plus (404) retombe sur '
      'l\'établissement', () async {
    const cycle = RecoveryQuestion(
      feeCodes: ['TUITION'],
      scope: RecoveryScopeKind.cycle,
      scopeId: 'gone',
    );
    when(
      () => repo.dashboard(
        any(),
        cycle,
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => const Left(NotFoundFailure('404')));
    when(
      () => repo.dashboard(
        any(),
        tuition,
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => Right(recoveryDashboardFixture()));
    final cubit = build();
    await cubit.ask('ay-1', cycle);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.question, tuition);
    expect(cubit.state.status, RecoveryLoadStatus.success);
    await cubit.close();
  });
}
