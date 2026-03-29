import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';

class ParentDetail extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phone;
  final String? email;
  final RelationshipType relationshipType;

  const ParentDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phone,
    this.email,
    required this.relationshipType,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    phone,
    email,
    relationshipType,
  ];
}
