import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';

class ParentSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String identificationNumber;
  final String phoneNumber;
  final String email;
  final RelationshipType relationshipType;

  const ParentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.identificationNumber,
    required this.phoneNumber,
    required this.email,
    required this.relationshipType,
  });
}
