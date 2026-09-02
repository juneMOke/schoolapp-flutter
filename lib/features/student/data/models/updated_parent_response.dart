import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

class UpdatedParentResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String identificationNumber;

  /// Facultatif depuis la V117 serveur : `null` quand le tuteur n'a pas de
  /// numéro. Le cast était dur — la première réponse d'un tuteur sans numéro
  /// aurait fait lever la mise à jour.
  final String? phoneNumber;
  final String email;
  final String relationshipType;

  const UpdatedParentResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.identificationNumber,
    this.phoneNumber,
    required this.email,
    required this.relationshipType,
  });

  factory UpdatedParentResponse.fromJson(Map<String, dynamic> json) =>
      UpdatedParentResponse(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        surname: json['surname'] as String?,
        identificationNumber: json['identificationNumber'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String,
        relationshipType: json['relationshipType'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'identificationNumber': identificationNumber,
    'phoneNumber': phoneNumber,
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
