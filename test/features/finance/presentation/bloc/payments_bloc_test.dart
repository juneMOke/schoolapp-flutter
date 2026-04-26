import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/create_payment_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payments_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';

class MockGetPaymentsUseCase extends Mock implements GetPaymentsUseCase {}

class MockGetPaymentAllocationsUseCase extends Mock
    implements GetPaymentAllocationsUseCase {}

class MockCreatePaymentUseCase extends Mock implements CreatePaymentUseCase {}

const _studentId = 'student-1';
const _academicYearId = 'year-1';
const _amountInCents = 150000;
const _currency = 'USD';
const _payerFirstName = 'Jean';
const _payerLastName = 'Dupont';
const _payerMiddleName = 'Pierre';
const _allocations = [
  CreatePaymentAllocationInput(
    studentChargeId: 'charge-1',
    feeCode: 'TUITION',
    studentChargeLabel: 'Tuition 2025-2026',
    amountInCents: _amountInCents,
    currency: _currency,
  ),
];

final _createdPayment = Payment(
  id: 'payment-1',
  studentId: _studentId,
  academicYearId: _academicYearId,
  amountInCents: _amountInCents,
  currency: _currency,
  payerFirstName: _payerFirstName,
  payerLastName: _payerLastName,
  payerMiddleName: _payerMiddleName,
  paidAt: DateTime(2026, 4, 25),
);

final _existingPayment = Payment(
  id: 'payment-existing',
  studentId: _studentId,
  academicYearId: _academicYearId,
  amountInCents: 50000,
  currency: _currency,
  payerFirstName: 'A',
  payerLastName: 'B',
  paidAt: DateTime(2026, 4, 24),
);

void main() {
  late MockGetPaymentsUseCase mockGetPaymentsUseCase;
  late MockGetPaymentAllocationsUseCase mockGetPaymentAllocationsUseCase;
  late MockCreatePaymentUseCase mockCreatePaymentUseCase;

  setUp(() {
    mockGetPaymentsUseCase = MockGetPaymentsUseCase();
    mockGetPaymentAllocationsUseCase = MockGetPaymentAllocationsUseCase();
    mockCreatePaymentUseCase = MockCreatePaymentUseCase();
  });

  PaymentsBloc buildBloc() => PaymentsBloc(
    getPaymentsUseCase: mockGetPaymentsUseCase,
    createPaymentUseCase: mockCreatePaymentUseCase,
    getPaymentAllocationsUseCase: mockGetPaymentAllocationsUseCase,
  );

  group('PaymentsCreateRequested', () {
    blocTest<PaymentsBloc, PaymentsState>(
      'emits [create loading, create success] and prepends created payment',
      setUp: () {
        when(
          () => mockCreatePaymentUseCase.call(
            studentId: _studentId,
            academicYearId: _academicYearId,
            amountInCents: _amountInCents,
            currency: _currency,
            payerFirstName: _payerFirstName,
            payerLastName: _payerLastName,
            payerMiddleName: _payerMiddleName,
            allocations: _allocations,
          ),
        ).thenAnswer((_) async => Right(_createdPayment));
      },
      build: buildBloc,
      seed: () => PaymentsState(
        status: PaymentsStatus.success,
        payments: [_existingPayment],
      ),
      act: (bloc) => bloc.add(
        const PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amountInCents: _amountInCents,
          currency: _currency,
          payerFirstName: _payerFirstName,
          payerLastName: _payerLastName,
          payerMiddleName: _payerMiddleName,
          allocations: _allocations,
        ),
      ),
      expect: () => [
        PaymentsState(
          status: PaymentsStatus.success,
          payments: [_existingPayment],
          createStatus: PaymentsStatus.loading,
          createErrorType: PaymentsErrorType.none,
        ),
        PaymentsState(
          status: PaymentsStatus.success,
          payments: [_createdPayment, _existingPayment],
          createStatus: PaymentsStatus.success,
          createErrorType: PaymentsErrorType.none,
          createdPayment: _createdPayment,
        ),
      ],
    );

    blocTest<PaymentsBloc, PaymentsState>(
      'emits [create loading, create failure(validation)] on ValidationFailure',
      setUp: () {
        when(
          () => mockCreatePaymentUseCase.call(
            studentId: _studentId,
            academicYearId: _academicYearId,
            amountInCents: _amountInCents,
            currency: _currency,
            payerFirstName: _payerFirstName,
            payerLastName: _payerLastName,
            payerMiddleName: _payerMiddleName,
            allocations: _allocations,
          ),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amountInCents: _amountInCents,
          currency: _currency,
          payerFirstName: _payerFirstName,
          payerLastName: _payerLastName,
          payerMiddleName: _payerMiddleName,
          allocations: _allocations,
        ),
      ),
      expect: () => const [
        PaymentsState(
          createStatus: PaymentsStatus.loading,
          createErrorType: PaymentsErrorType.none,
        ),
        PaymentsState(
          createStatus: PaymentsStatus.failure,
          createErrorType: PaymentsErrorType.validation,
        ),
      ],
    );

    blocTest<PaymentsBloc, PaymentsState>(
      'emits [create loading, create failure(network)] on NetworkFailure',
      setUp: () {
        when(
          () => mockCreatePaymentUseCase.call(
            studentId: _studentId,
            academicYearId: _academicYearId,
            amountInCents: _amountInCents,
            currency: _currency,
            payerFirstName: _payerFirstName,
            payerLastName: _payerLastName,
            payerMiddleName: _payerMiddleName,
            allocations: _allocations,
          ),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amountInCents: _amountInCents,
          currency: _currency,
          payerFirstName: _payerFirstName,
          payerLastName: _payerLastName,
          payerMiddleName: _payerMiddleName,
          allocations: _allocations,
        ),
      ),
      expect: () => const [
        PaymentsState(
          createStatus: PaymentsStatus.loading,
          createErrorType: PaymentsErrorType.none,
        ),
        PaymentsState(
          createStatus: PaymentsStatus.failure,
          createErrorType: PaymentsErrorType.network,
        ),
      ],
    );
  });
}
