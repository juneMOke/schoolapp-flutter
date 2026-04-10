import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';

class ParentItemValue extends Equatable {
  final String firstName;
  final String lastName;
  final String surname;
  final String identificationNumber;
  final String phoneNumber;
  final String email;
  final RelationshipType relationshipType;

  const ParentItemValue({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.identificationNumber,
    required this.phoneNumber,
    required this.email,
    required this.relationshipType,
  });

  factory ParentItemValue.fromParent(ParentSummary parent) {
    return ParentItemValue(
      firstName: parent.firstName,
      lastName: parent.lastName,
      surname: parent.surname ?? '',
      identificationNumber: parent.identificationNumber,
      phoneNumber: parent.phoneNumber,
      email: parent.email,
      relationshipType: parent.relationshipType,
    );
  }

  ParentItemValue copyWith({
    String? firstName,
    String? lastName,
    String? surname,
    String? identificationNumber,
    String? phoneNumber,
    String? email,
    RelationshipType? relationshipType,
  }) {
    return ParentItemValue(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      surname: surname ?? this.surname,
      identificationNumber: identificationNumber ?? this.identificationNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationshipType: relationshipType ?? this.relationshipType,
    );
  }

  bool get isValid {
    return firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        identificationNumber.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        email.trim().isNotEmpty;
  }

  Map<String, bool> changedComparedTo(ParentItemValue initial) {
    return <String, bool>{
      'firstName': firstName.trim() != initial.firstName.trim(),
      'lastName': lastName.trim() != initial.lastName.trim(),
      'surname': surname.trim() != initial.surname.trim(),
      'identificationNumber':
          identificationNumber.trim() != initial.identificationNumber.trim(),
      'phoneNumber': phoneNumber.trim() != initial.phoneNumber.trim(),
      'email': email.trim() != initial.email.trim(),
      'relationshipType': relationshipType != initial.relationshipType,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        firstName,
        lastName,
        surname,
        identificationNumber,
        phoneNumber,
        email,
        relationshipType,
      ];
}

class ParentItemFormState extends Equatable {
  final bool valid;
  final bool dirty;
  final Map<String, bool> changedFields;

  const ParentItemFormState({
    required this.valid,
    required this.dirty,
    required this.changedFields,
  });

  const ParentItemFormState.initial()
      : valid = false,
        dirty = false,
        changedFields = const <String, bool>{};

  @override
  List<Object?> get props => <Object?>[valid, dirty, changedFields];
}