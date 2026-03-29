part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordFlowResetRequested extends ForgotPasswordEvent {
  const ForgotPasswordFlowResetRequested();
}

class ForgotPasswordGenerateOtpRequested extends ForgotPasswordEvent {
  final String userEmail;

  const ForgotPasswordGenerateOtpRequested({required this.userEmail});

  @override
  List<Object?> get props => [userEmail];
}

class ForgotPasswordValidateOtpRequested extends ForgotPasswordEvent {
  final String userEmail;
  final String code;

  const ForgotPasswordValidateOtpRequested({
    required this.userEmail,
    required this.code,
  });

  @override
  List<Object?> get props => [userEmail, code];
}
