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

  /// Tuteur à appeler en urgence **pour l'élève de ce dossier** — au plus un
  /// par élève. Comme [relationshipType], il décrit le couple (élève, tuteur)
  /// et non le tuteur : un même adulte peut l'être pour un enfant et pas pour
  /// son frère.
  final bool emergencyContact;

  const ParentSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.identificationNumber,
    required this.phoneNumber,
    required this.email,
    required this.relationshipType,
    this.emergencyContact = false,
  });
}
