part of 'forgot_password_bloc.dart';

const _undefined = Object();

enum ForgotPasswordStatus {
  initial,
  loading,
  otpGenerated,
  otpValidated,
  failure,
}

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;
  final String? userEmail;
  final String? resetToken;
  final String? errorMessage;

  const ForgotPasswordState({
    required this.status,
    this.userEmail,
    this.resetToken,
    this.errorMessage,
  });

  const ForgotPasswordState.initial()
    : status = ForgotPasswordStatus.initial,
      userEmail = null,
      resetToken = null,
      errorMessage = null;

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    Object? userEmail = _undefined,
    Object? resetToken = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      userEmail: identical(userEmail, _undefined)
          ? this.userEmail
          : userEmail as String?,
      resetToken: identical(resetToken, _undefined)
          ? this.resetToken
          : resetToken as String?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, userEmail, resetToken, errorMessage];
}
