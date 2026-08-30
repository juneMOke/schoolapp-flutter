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
  final bool? emergencyContact;

  const ParentSummaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.identificationNumber,
    required this.phoneNumber,
    required this.email,
    required this.relationshipType,
    this.emergencyContact,
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
        // Le serveur le rend nul dans les vues sans élève de référence
        // (recherche, mise à jour) : `null` y veut dire « la question ne se
        // pose pas », pas « non ».
        emergencyContact: json['emergencyContact'] as bool?,
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
    'emergencyContact': emergencyContact,
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
    emergencyContact: emergencyContact ?? false,
  );
}
