import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class UserModel {
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String schoolId;

  const UserModel({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    role: json['role'] as String,
    schoolId:
        (json['schoolId'] ?? json['school_id'] ?? json['schoolUUID'] ?? '')
            as String,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'schoolId': schoolId,
  };

  AuthenticatedUser toAuthenticatedUser() => AuthenticatedUser(
    email: email,
    firstName: firstName,
    lastName: lastName,
    role: role,
    schoolId: schoolId,
  );
}
