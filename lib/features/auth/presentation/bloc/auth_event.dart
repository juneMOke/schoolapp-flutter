import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;
  final String newPassword;
  final String otpToken;

  const AuthResetPasswordRequested({
    required this.email,
    required this.newPassword,
    required this.otpToken,
  });

  @override
  List<Object?> get props => [email, newPassword, otpToken];
}
