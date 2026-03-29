import 'package:school_app_flutter/features/enrollment/domain/entities/parent_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';

class ParentDetailModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phone;
  final String? email;
  final String relationshipType;

  const ParentDetailModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phone,
    this.email,
    required this.relationshipType,
  });

  factory ParentDetailModel.fromJson(Map<String, dynamic> json) =>
      ParentDetailModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        surname: json['surname'] as String?,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        relationshipType: json['relationshipType'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'phone': phone,
    'email': email,
    'relationshipType': relationshipType,
  };

  ParentDetail toParentDetail() => ParentDetail(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    phone: phone,
    email: email,
    relationshipType: RelationshipType.fromString(relationshipType),
  );
}
