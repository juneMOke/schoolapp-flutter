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
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class MockGetPaymentsUseCase extends Mock implements GetPaymentsUseCase {}

class MockGetPaymentAllocationsUseCase extends Mock
    implements GetPaymentAllocationsUseCase {}

class MockCreatePaymentUseCase extends Mock implements CreatePaymentUseCase {}

const _studentId = 'student-1';
const _academicYearId = 'year-1';
const _amountInCents = 150000;
const _currency = 'USD';

/// Ce qui est encaissé, par devise — le versement n'a plus de montant à lui.
final _amounts = MoneyBag.of(const [Money(_amountInCents, _currency)]);
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
  amounts: _amounts,
  payerFirstName: _payerFirstName,
  payerLastName: _payerLastName,
  payerMiddleName: _payerMiddleName,
  paidAt: DateTime(2026, 4, 25),
);

final _existingPayment = Payment(
  id: 'payment-existing',
  studentId: _studentId,
  academicYearId: _academicYearId,
  amounts: MoneyBag.of(const [Money(50000, _currency)]),
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

  // Jumeau du groupe silencieux de `StudentChargesBloc` : c'est cette section
  // qui replie l'historique en « total payé », l'effacer sur un échec de
  // relecture de fond ferait afficher un total faux au moment d'encaisser.
  group('PaymentsRequested silencieux', () {
    const params = GetPaymentsParams(
      studentId: _studentId,
      academicYearId: _academicYearId,
    );

    blocTest<PaymentsBloc, PaymentsState>(
      'relecture silencieuse : aucun passage par loading',
      setUp: () {
        when(
          () => mockGetPaymentsUseCase(params),
        ).thenAnswer((_) async => Right([_existingPayment]));
      },
      build: buildBloc,
      seed: () => const PaymentsState(status: PaymentsStatus.success),
      act: (bloc) => bloc.add(
        const PaymentsRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          silent: true,
        ),
      ),
      expect: () => [
        PaymentsState(
          status: PaymentsStatus.success,
          payments: [_existingPayment],
        ),
      ],
    );

    blocTest<PaymentsBloc, PaymentsState>(
      'échec d\'une relecture silencieuse : l\'historique affiché survit',
      setUp: () {
        when(
          () => mockGetPaymentsUseCase(params),
        ).thenAnswer((_) async => const Left(NetworkFailure('lien coupé')));
      },
      build: buildBloc,
      seed: () => PaymentsState(
        status: PaymentsStatus.success,
        payments: [_existingPayment],
      ),
      act: (bloc) => bloc.add(
        const PaymentsRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          silent: true,
        ),
      ),
      expect: () => const <PaymentsState>[],
    );
  });

  group('PaymentsCreateRequested', () {
    blocTest<PaymentsBloc, PaymentsState>(
      'emits [create loading, create success] and prepends created payment',
      setUp: () {
        when(
          () => mockCreatePaymentUseCase.call(
            studentId: _studentId,
            academicYearId: _academicYearId,
            amounts: _amounts,
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
        PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amounts: _amounts,
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
            amounts: _amounts,
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
        PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amounts: _amounts,
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
            amounts: _amounts,
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
        PaymentsCreateRequested(
          studentId: _studentId,
          academicYearId: _academicYearId,
          amounts: _amounts,
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
