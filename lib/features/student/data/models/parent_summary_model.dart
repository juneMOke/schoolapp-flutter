import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

class ParentSummaryModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String identificationNumber;
  final String phoneNumber;
  final String email;
  final String relationshipType;

  const ParentSummaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.identificationNumber,
    required this.phoneNumber,
    required this.email,
    required this.relationshipType,
  });

  factory ParentSummaryModel.fromJson(Map<String, dynamic> json) =>
      ParentSummaryModel(
        id: _readString(json['id']),
        firstName: _readString(json['firstName']),
        lastName: _readString(json['lastName']),
        surname: _readString(json['surname']),
        identificationNumber: _readString(json['identificationNumber']),
        phoneNumber: _readString(json['phoneNumber']),
        email: _readString(json['email']),
        relationshipType: _readString(json['relationshipType']),
      );

  static String _readString(dynamic value) => value?.toString() ?? '';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'phone': phoneNumber,
    'email': email,
    'relationshipType': relationshipType,
  };

  ParentSummary toParentSummary() => ParentSummary(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    identificationNumber: identificationNumber,
    phoneNumber: phoneNumber,
    email: email,
    relationshipType: RelationshipType.fromString(relationshipType),
  );
}
