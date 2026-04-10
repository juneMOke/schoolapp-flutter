import 'package:equatable/equatable.dart';

class AuthenticatedUser extends Equatable {
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String schoolId;

  const AuthenticatedUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [email, firstName, lastName, role, schoolId];
}
