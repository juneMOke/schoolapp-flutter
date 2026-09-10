import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_list.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/relance_scope.dart';
import 'package:school_app_flutter/features/recouvrement/domain/usecases/emit_relance_list_usecase.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/relance_list_cubit.dart';

class _MockEmit extends Mock implements EmitRelanceListUseCase {}

class _MockCount extends Mock implements CountPendingPaymentsUseCase {}

class _FakeScope extends Fake implements RelanceScope {}

final _document = RelanceList(
  bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
  fileName: 'relance.pdf',
);

LocalRecoveryLine line(String studentId) => LocalRecoveryLine(
  schoolLevelId: 'lvl-1',
  studentId: studentId,
  charges: [
    RecoveryChargePosition(
      feeCode: 'TUITION',
      position: FeeChargePosition(
        currency: 'USD',
        expectedInCents: 30000,
        paidMirrorInCents: 0,
        paidPendingInCents: 0,
      ),
    ),
  ],
);

void main() {
  late _MockEmit emitUseCase;
  late _MockCount countUseCase;

  setUpAll(() {
    registerFallbackValue(_FakeScope());
    registerFallbackValue(RecouvrementCriterion.noPayment);
  });

  setUp(() {
    emitUseCase = _MockEmit();
    countUseCase = _MockCount();
    when(() => countUseCase()).thenAnswer((_) async => const Right(0));
  });

  RelanceListCubit build() => RelanceListCubit(
    emitRelanceList: emitUseCase,
    countPendingPayments: countUseCase,
  );

  void stubEmit(Either<Failure, RelanceList> result) {
    when(
      () => emitUseCase(
        scope: any(named: 'scope'),
        feeCodes: any(named: 'feeCodes'),
        criterion: any(named: 'criterion'),
        lines: any(named: 'lines'),
        arretedAt: any(named: 'arretedAt'),
        thresholdInCents: any(named: 'thresholdInCents'),
        thresholdCurrency: any(named: 'thresholdCurrency'),
        pendingWrites: any(named: 'pendingWrites'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> run(RelanceListCubit cubit) => cubit.emit_(
    scope: RelanceScope.schoolLevel('lvl-1'),
    feeCodes: const ['TUITION'],
    criterion: RecouvrementCriterion.noPayment,
    lines: [line('s1')],
  );

  group('les trois états qui survivent au tap', () {
    blocTest<RelanceListCubit, RelanceListState>(
      'succès : préparation, puis le document remis',
      setUp: () => stubEmit(Right(_document)),
      build: build,
      act: run,
      expect: () => [
        isA<RelanceListState>()
            .having((s) => s.status, 'status', RelanceListStatus.preparing)
            .having((s) => s.isBusy, 'désarmé', isTrue),
        isA<RelanceListState>()
            .having((s) => s.status, 'status', RelanceListStatus.idle)
            .having((s) => s.document, 'document', _document),
      ],
    );

    blocTest<RelanceListCubit, RelanceListState>(
      'un 429 n\'est pas une panne : la ligne reste désarmée le temps annoncé',
      setUp: () => stubEmit(
        const Left(TooManyRequestsFailure(retryAfter: Duration(seconds: 30))),
      ),
      build: build,
      act: run,
      skip: 1,
      expect: () => [
        isA<RelanceListState>()
            .having((s) => s.status, 'status', RelanceListStatus.cooldown)
            .having((s) => s.retryAfter, 'délai', const Duration(seconds: 30))
            .having((s) => s.isBusy, 'toujours désarmé', isTrue),
      ],
    );

    blocTest<RelanceListCubit, RelanceListState>(
      'un second appui pendant la préparation ne lance RIEN',
      setUp: () => stubEmit(Right(_document)),
      build: build,
      act: (cubit) async {
        unawaited(run(cubit));
        await run(cubit);
      },
      verify: (_) => verify(
        () => emitUseCase(
          scope: any(named: 'scope'),
          feeCodes: any(named: 'feeCodes'),
          criterion: any(named: 'criterion'),
          lines: any(named: 'lines'),
          arretedAt: any(named: 'arretedAt'),
          thresholdInCents: any(named: 'thresholdInCents'),
          thresholdCurrency: any(named: 'thresholdCurrency'),
          pendingWrites: any(named: 'pendingWrites'),
        ),
      ).called(1),
    );
  });

  group('le document est remis PUIS oublié', () {
    test('acknowledge le retire — le serveur n\'archive rien', () async {
      stubEmit(Right(_document));
      final cubit = build();
      addTearDown(cubit.close);

      await run(cubit);
      expect(cubit.state.document, isNotNull);

      cubit.acknowledge();
      expect(
        cubit.state.document,
        isNull,
        reason:
            'un document laissé là se ferait re-présenter comme « la » '
            'liste, alors qu\'il n\'en est qu\'un tirage',
      );
    });

    test('acknowledge conserve l\'attente d\'un 429', () async {
      stubEmit(
        const Left(TooManyRequestsFailure(retryAfter: Duration(seconds: 30))),
      );
      final cubit = build();
      addTearDown(cubit.close);

      await run(cubit);
      cubit.acknowledge();

      expect(cubit.state.status, RelanceListStatus.cooldown);
      expect(cubit.state.failure, isNull);
    });
  });

  group('les écritures en attente', () {
    test('sont comptées au plus près de l\'envoi', () async {
      when(() => countUseCase()).thenAnswer((_) async => const Right(3));
      stubEmit(Right(_document));
      final cubit = build();
      addTearDown(cubit.close);

      await run(cubit);

      final captured = verify(
        () => emitUseCase(
          scope: any(named: 'scope'),
          feeCodes: any(named: 'feeCodes'),
          criterion: any(named: 'criterion'),
          lines: any(named: 'lines'),
          arretedAt: any(named: 'arretedAt'),
          thresholdInCents: any(named: 'thresholdInCents'),
          thresholdCurrency: any(named: 'thresholdCurrency'),
          pendingWrites: captureAny(named: 'pendingWrites'),
        ),
      ).captured.single;
      expect(captured, 3);
    });

    test('zéro ne s\'imprime pas : la mention se tait', () async {
      when(() => countUseCase()).thenAnswer((_) async => const Right(0));
      stubEmit(Right(_document));
      final cubit = build();
      addTearDown(cubit.close);

      await run(cubit);

      final captured = verify(
        () => emitUseCase(
          scope: any(named: 'scope'),
          feeCodes: any(named: 'feeCodes'),
          criterion: any(named: 'criterion'),
          lines: any(named: 'lines'),
          arretedAt: any(named: 'arretedAt'),
          thresholdInCents: any(named: 'thresholdInCents'),
          thresholdCurrency: any(named: 'thresholdCurrency'),
          pendingWrites: captureAny(named: 'pendingWrites'),
        ),
      ).captured.single;
      expect(captured, isNull);
    });

    test(
      'un comptage en échec n\'empêche pas d\'éditer : la mention disparaît',
      () async {
        when(
          () => countUseCase(),
        ).thenAnswer((_) async => const Left(StorageFailure('boum')));
        stubEmit(Right(_document));
        final cubit = build();
        addTearDown(cubit.close);

        await run(cubit);

        expect(
          cubit.state.document,
          isNotNull,
          reason: 'la mention est un appoint, pas une condition',
        );
      },
    );
  });
}
