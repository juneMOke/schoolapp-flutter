import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/create_payment_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payments_usecase.dart';

part 'payments_event.dart';
part 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final GetPaymentsUseCase _getPaymentsUseCase;
  final CreatePaymentUseCase _createPaymentUseCase;
  final GetPaymentAllocationsUseCase _getPaymentAllocationsUseCase;

  PaymentsBloc({
    required GetPaymentsUseCase getPaymentsUseCase,
    required CreatePaymentUseCase createPaymentUseCase,
    required GetPaymentAllocationsUseCase getPaymentAllocationsUseCase,
  }) : _getPaymentsUseCase = getPaymentsUseCase,
       _createPaymentUseCase = createPaymentUseCase,
       _getPaymentAllocationsUseCase = getPaymentAllocationsUseCase,
       super(const PaymentsState()) {
    on<PaymentsRequested>(_onPaymentsRequested);
    on<PaymentsCreateRequested>(_onPaymentsCreateRequested);
    on<PaymentsAllocationsRequested>(_onPaymentsAllocationsRequested);
  }

  Future<void> _onPaymentsRequested(
    PaymentsRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PaymentsStatus.loading,
        errorType: PaymentsErrorType.none,
      ),
    );

    final result = await _getPaymentsUseCase(
      GetPaymentsParams(
        studentId: event.studentId,
        academicYearId: event.academicYearId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PaymentsStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (payments) => emit(
        state.copyWith(
          status: PaymentsStatus.success,
          payments: payments,
          errorType: PaymentsErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onPaymentsAllocationsRequested(
    PaymentsAllocationsRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(
      state.copyWith(
        allocationsStatus: PaymentsStatus.loading,
        allocationsErrorType: PaymentsErrorType.none,
      ),
    );

    final result = await _getPaymentAllocationsUseCase(
      GetPaymentAllocationsParams(paymentId: event.paymentId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          allocationsStatus: PaymentsStatus.failure,
          allocationsErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (allocations) {
        final nextAllocations = Map<String, List<PaymentAllocation>>.from(
          state.allocationsByPaymentId,
        )..[event.paymentId] = allocations;

        emit(
          state.copyWith(
            allocationsStatus: PaymentsStatus.success,
            allocationsByPaymentId: nextAllocations,
            allocationsErrorType: PaymentsErrorType.none,
          ),
        );
      },
    );
  }

  Future<void> _onPaymentsCreateRequested(
    PaymentsCreateRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    emit(
      state.copyWith(
        createStatus: PaymentsStatus.loading,
        createErrorType: PaymentsErrorType.none,
      ),
    );

    final result = await _createPaymentUseCase(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
      amountInCents: event.amountInCents,
      currency: event.currency,
      payerFirstName: event.payerFirstName,
      payerLastName: event.payerLastName,
      payerMiddleName: event.payerMiddleName,
      allocations: event.allocations,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          createStatus: PaymentsStatus.failure,
          createErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (createdPayment) {
        final nextPayments = [
          createdPayment,
          ...state.payments.where((payment) => payment.id != createdPayment.id),
        ];

        emit(
          state.copyWith(
            createStatus: PaymentsStatus.success,
            createErrorType: PaymentsErrorType.none,
            createdPayment: createdPayment,
            payments: nextPayments,
          ),
        );
      },
    );
  }

  PaymentsErrorType _mapFailureToErrorType(Failure failure) => switch (failure) {
    NetworkFailure() => PaymentsErrorType.network,
    NotFoundFailure() => PaymentsErrorType.notFound,
    ValidationFailure() => PaymentsErrorType.validation,
    UnauthorizedFailure() => PaymentsErrorType.unauthorized,
    InvalidCredentialsFailure() => PaymentsErrorType.invalidCredentials,
    ServerFailure() => PaymentsErrorType.server,
    StorageFailure() => PaymentsErrorType.storage,
    AuthFailure() => PaymentsErrorType.auth,
    _ => PaymentsErrorType.unknown,
  };
}