import 'package:school_app_flutter/features/auth/domain/entities/authenticated_user.dart';

class UserModel {
  /// UUID serveur (`user.id`, ADR-010 §0.2 A1). Vide si le backend ne l'expose
  /// pas encore (session héritée).
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String schoolId;

  const UserModel({
    this.id = '',
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.schoolId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: (json['id'] ?? json['uid'] ?? json['userId'] ?? '') as String,
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    role: json['role'] as String,
    schoolId:
        (json['schoolId'] ?? json['school_id'] ?? json['schoolUUID'] ?? '')
            as String,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'schoolId': schoolId,
  };

  AuthenticatedUser toAuthenticatedUser() => AuthenticatedUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    role: role,
    schoolId: schoolId,
  );
}
