import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_student_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';

class _MockCharges extends Mock implements GetLocalStudentChargesUseCase {}

class _MockPayments extends Mock implements GetLocalPaymentsUseCase {}

class _MockRecord extends Mock implements RecordPaymentUseCase {}

/// La garde d'une correction de niveau (D7) n'est pas une panne : l'écran doit
/// pouvoir la reconnaître sans lire un message.
void main() {
  const draft = RecordPaymentDraft(
    studentId: 's1',
    academicYearId: 'ay-1',
    paidAt: '2026-11-08T10:00:00Z',
    allocations: [],
  );
  late _MockRecord record;

  setUpAll(() => registerFallbackValue(draft));
  setUp(() => record = _MockRecord());

  FinanceOfflineBloc build() => FinanceOfflineBloc(
    getCharges: _MockCharges(),
    getPayments: _MockPayments(),
    recordPayment: record,
  );

  blocTest<FinanceOfflineBloc, FinanceOfflineState>(
    'retenu par une correction de niveau : erreur marquée comme telle',
    setUp: () => when(
      () => record(any()),
    ).thenAnswer((_) async => const Left(LevelCorrectionHoldFailure())),
    build: build,
    act: (bloc) => bloc.add(const RecordLocalPayment(draft)),
    expect: () => [
      const FinanceOfflineRecording(),
      isA<FinanceOfflineError>().having(
        (e) => e.heldByLevelCorrection,
        'heldByLevelCorrection',
        isTrue,
      ),
    ],
  );

  blocTest<FinanceOfflineBloc, FinanceOfflineState>(
    'une autre panne ne se dit pas retenue',
    setUp: () => when(
      () => record(any()),
    ).thenAnswer((_) async => const Left(StorageFailure('disque'))),
    build: build,
    act: (bloc) => bloc.add(const RecordLocalPayment(draft)),
    expect: () => [
      const FinanceOfflineRecording(),
      isA<FinanceOfflineError>().having(
        (e) => e.heldByLevelCorrection,
        'heldByLevelCorrection',
        isFalse,
      ),
    ],
  );
}
