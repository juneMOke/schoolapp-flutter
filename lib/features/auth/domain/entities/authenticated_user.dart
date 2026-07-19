import 'package:equatable/equatable.dart';

class AuthenticatedUser extends Equatable {
  /// UUID serveur = claim `uid` du JWT (ADR-010 §0.2). C'est l'`authorId`
  /// canonique estampillé sur les écritures offline (D-05). Peut être vide sur
  /// une session héritée pré-ADR-010.
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String schoolId;

  const AuthenticatedUser({
    this.id = '',
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [id, email, firstName, lastName, role, schoolId];
}
