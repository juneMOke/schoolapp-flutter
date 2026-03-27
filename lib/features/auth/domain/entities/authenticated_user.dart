import 'package:equatable/equatable.dart';

class AuthenticatedUser extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String createdAt;

  const AuthenticatedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, firstName, lastName, role, createdAt];
}
