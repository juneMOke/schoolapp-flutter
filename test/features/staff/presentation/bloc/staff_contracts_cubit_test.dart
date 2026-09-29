import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_state.dart';

class _MockRepository extends Mock implements StaffContractRepository {}

const _contract = StaffContract(
  id: 'c-1',
  staffMemberId: 'm-1',
  kind: StaffContractKind.permanent,
  effectiveFrom: '2025-09-01',
  recordedAt: '2025-09-01T08:00:00Z',
  syncState: StaffSyncState.synced,
);

void main() {
  late _MockRepository repository;
  late StaffContractsCubit cubit;

  setUpAll(() {
    registerFallbackValue(const StaffContractDraft());
    registerFallbackValue(_contract);
  });

  setUp(() {
    repository = _MockRepository();
    cubit = StaffContractsCubit(
      load: LoadStaffContractsUseCase(repository),
      add: AddStaffContractUseCase(repository),
      correct: CorrectStaffContractUseCase(repository),
    );
    when(
      () => repository.contractsOf(any()),
    ).thenAnswer((_) async => const Right([_contract]));
  });
  tearDown(() => cubit.close());

  test('une lecture ratée cache les montants, sans erreur affichée', () async {
    when(
      () => repository.contractsOf(any()),
    ).thenAnswer((_) async => const Left(StorageFailure('x')));

    await cubit.load('m-1');

    expect(cubit.state.contracts, isEmpty);
    expect(cubit.state.outcome, isNull);
  });

  test('un geste réussi relit les périodes et s annonce', () async {
    when(
      () => repository.addContract(any(), any()),
    ).thenAnswer((_) async => const Right(unit));

    expect(await cubit.add('m-1', const StaffContractDraft()), isTrue);

    expect(cubit.state.contracts, [_contract]);
    expect(cubit.state.outcome, StaffContractOutcome.saved);
    expect(cubit.state.outcomeSeq, 1);
    expect(cubit.state.writing, isFalse);
  });

  test('deux échecs de suite s annoncent chacun', () async {
    when(
      () => repository.correctContract(
        any(),
        reason: any(named: 'reason'),
        replacement: any(named: 'replacement'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('x')));

    await cubit.correct(_contract, reason: 'doublon');
    await cubit.correct(_contract, reason: 'doublon');

    expect(cubit.state.outcome, StaffContractOutcome.failed);
    expect(cubit.state.outcomeSeq, 2);
    expect(cubit.state.failure, isA<StorageFailure>());
  });

  test('un second geste pendant l écriture est ignoré', () async {
    final gate = Completer<Either<Failure, Unit>>();
    when(
      () => repository.addContract(any(), any()),
    ).thenAnswer((_) => gate.future);

    final first = cubit.add('m-1', const StaffContractDraft());
    expect(await cubit.add('m-1', const StaffContractDraft()), isFalse);
    gate.complete(const Right(unit));
    expect(await first, isTrue);
    verify(() => repository.addContract(any(), any())).called(1);
  });
}
