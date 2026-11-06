import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refused_locally.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_status_cubit.dart';

class _MockCorrect extends Mock implements CorrectLevelUseCase {}

class _MockLoad extends Mock implements LoadLevelCorrectionUseCase {}

const _request = LevelCorrectionRequest(
  enrollmentId: 'enr-1',
  studentId: 'stu-1',
  academicYearId: 'year-1',
  fromSchoolLevelId: 'lvl-m2',
  toSchoolLevelId: 'lvl-p2',
  toSchoolLevelGroupId: 'grp',
  reason: 'Motif',
);

LevelCorrection _correction(LevelCorrectionStatus status) => LevelCorrection(
  id: 'g-1',
  enrollmentId: 'enr-1',
  studentId: 'stu-1',
  academicYearId: 'year-1',
  fromSchoolLevelId: 'lvl-m2',
  toSchoolLevelId: 'lvl-p2',
  toSchoolLevelGroupId: 'grp',
  reason: 'Motif',
  correctedAt: '2026-11-06T10:15:00.000Z',
  status: status,
);

void main() {
  setUpAll(() => registerFallbackValue(_request));

  group('LevelCorrectionGestureCubit', () {
    late _MockCorrect correct;
    setUp(() => correct = _MockCorrect());

    blocTest<LevelCorrectionGestureCubit, LevelCorrectionGestureState>(
      'posée : occupé puis fait',
      setUp: () =>
          when(() => correct(any())).thenAnswer((_) async => const Right(true)),
      build: () => LevelCorrectionGestureCubit(correct),
      act: (cubit) => cubit.submit(_request),
      expect: () => const [
        LevelCorrectionGestureBusy(),
        LevelCorrectionGestureDone(),
      ],
    );

    blocTest<LevelCorrectionGestureCubit, LevelCorrectionGestureState>(
      'une autre attend déjà',
      setUp: () => when(
        () => correct(any()),
      ).thenAnswer((_) async => const Right(false)),
      build: () => LevelCorrectionGestureCubit(correct),
      act: (cubit) => cubit.submit(_request),
      expect: () => const [
        LevelCorrectionGestureBusy(),
        LevelCorrectionGestureFailed(
          LevelCorrectionGestureProblem.alreadyPending,
        ),
      ],
    );

    blocTest<LevelCorrectionGestureCubit, LevelCorrectionGestureState>(
      'refus local : le motif du refus suit',
      setUp: () => when(() => correct(any())).thenAnswer(
        (_) async => const Left(
          LevelCorrectionRefusedLocally(LevelCorrectionRefusal.hasPayments),
        ),
      ),
      build: () => LevelCorrectionGestureCubit(correct),
      act: (cubit) => cubit.submit(_request),
      expect: () => const [
        LevelCorrectionGestureBusy(),
        LevelCorrectionGestureFailed(
          LevelCorrectionGestureProblem.refusedLocally,
          refusal: LevelCorrectionRefusal.hasPayments,
        ),
      ],
    );

    blocTest<LevelCorrectionGestureCubit, LevelCorrectionGestureState>(
      'écriture en échec',
      setUp: () => when(
        () => correct(any()),
      ).thenAnswer((_) async => const Left(StorageFailure('x'))),
      build: () => LevelCorrectionGestureCubit(correct),
      act: (cubit) => cubit.submit(_request),
      expect: () => const [
        LevelCorrectionGestureBusy(),
        LevelCorrectionGestureFailed(LevelCorrectionGestureProblem.writeFailed),
      ],
    );

    test('un second envoi pendant le premier est ignoré', () async {
      final gate = Completer<Either<Failure, bool>>();
      when(() => correct(any())).thenAnswer((_) => gate.future);
      final cubit = LevelCorrectionGestureCubit(correct);
      unawaited(cubit.submit(_request));
      await cubit.submit(_request);
      gate.complete(const Right(true));
      await pumpEventQueue();
      verify(() => correct(any())).called(1);
      await cubit.close();
    });
  });

  group('LevelCorrectionStatusCubit', () {
    late _MockLoad load;
    late StreamController<Set<String>> changes;

    setUp(() {
      load = _MockLoad();
      changes = StreamController<Set<String>>.broadcast();
    });
    tearDown(() => changes.close());

    test(
      'se lit au montage, puis à chaque changement de son inscription',
      () async {
        var status = LevelCorrectionStatus.pending;
        when(
          () => load('enr-1'),
        ).thenAnswer((_) async => Right(_correction(status)));
        final cubit = LevelCorrectionStatusCubit(
          load,
          changes: changes.stream,
          enrollmentId: 'enr-1',
        );
        await pumpEventQueue();
        expect(cubit.state.isPending, isTrue);

        status = LevelCorrectionStatus.applied;
        changes.add({'enr-2'});
        await pumpEventQueue();
        expect(cubit.state.isPending, isTrue);

        changes.add({'enr-1'});
        await pumpEventQueue();
        expect(cubit.state.correction?.status, LevelCorrectionStatus.applied);
        await cubit.close();
      },
    );

    test('une lecture ratée garde l\'état connu', () async {
      var fail = false;
      when(() => load('enr-1')).thenAnswer(
        (_) async => fail
            ? const Left(StorageFailure('x'))
            : Right(_correction(LevelCorrectionStatus.pending)),
      );
      final cubit = LevelCorrectionStatusCubit(
        load,
        changes: changes.stream,
        enrollmentId: 'enr-1',
      );
      await pumpEventQueue();
      fail = true;
      changes.add({'enr-1'});
      await pumpEventQueue();
      expect(cubit.state.isPending, isTrue);
      await cubit.close();
    });
  });
}
