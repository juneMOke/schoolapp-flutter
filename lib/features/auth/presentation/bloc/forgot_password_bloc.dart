import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/generate_otp_use_case.dart';
import 'package:school_app_flutter/features/auth/domain/usecases/validate_otp_use_case.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final GenerateOtpUseCase generateOtpUseCase;
  final ValidateOtpUseCase validateOtpUseCase;

  ForgotPasswordBloc({
    required this.generateOtpUseCase,
    required this.validateOtpUseCase,
  }) : super(const ForgotPasswordState.initial()) {
    on<ForgotPasswordFlowResetRequested>(_onFlowResetRequested);
    on<ForgotPasswordGenerateOtpRequested>(_onGenerateOtpRequested);
    on<ForgotPasswordValidateOtpRequested>(_onValidateOtpRequested);
  }

  FutureOr<void> _onFlowResetRequested(
    ForgotPasswordFlowResetRequested event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordState.initial());
  }

  Future<void> _onGenerateOtpRequested(
    ForgotPasswordGenerateOtpRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        userEmail: event.userEmail,
        errorMessage: null,
        resetToken: null,
      ),
    );

    final result = await generateOtpUseCase(email: event.userEmail);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: ForgotPasswordStatus.otpGenerated,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onValidateOtpRequested(
    ForgotPasswordValidateOtpRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ForgotPasswordStatus.loading,
        userEmail: event.userEmail,
        errorMessage: null,
      ),
    );

    final result = await validateOtpUseCase(
      email: event.userEmail,
      code: event.code,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (token) => emit(
        state.copyWith(
          status: ForgotPasswordStatus.otpValidated,
          resetToken: token.value,
          errorMessage: null,
        ),
      ),
    );
  }
}
