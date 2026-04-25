import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payments_usecase.dart';

part 'payments_event.dart';
part 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final GetPaymentsUseCase _getPaymentsUseCase;

  PaymentsBloc({required GetPaymentsUseCase getPaymentsUseCase})
    : _getPaymentsUseCase = getPaymentsUseCase,
      super(const PaymentsState()) {
    on<PaymentsRequested>(_onPaymentsRequested);
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