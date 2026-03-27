import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        role: json['role'] as String,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'createdAt': createdAt,
      };

  AuthenticatedUser toAuthenticatedUser() => AuthenticatedUser(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        createdAt: createdAt,
      );
}
