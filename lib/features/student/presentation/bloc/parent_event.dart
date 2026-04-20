part of 'parent_bloc.dart';

sealed class ParentEvent extends Equatable {
  const ParentEvent();

  @override
  List<Object?> get props => [];
}

class ParentStateReset extends ParentEvent {
  const ParentStateReset();
}

class ParentUpdateRequested extends ParentEvent {
  final String parentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String email;
  final String phoneNumber;
  final String relationshipType;

  const ParentUpdateRequested({
    required this.parentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.email,
    required this.phoneNumber,
    required this.relationshipType,
  });

  @override
  List<Object?> get props => [
    parentId,
    firstName,
    lastName,
    surname,
    email,
    phoneNumber,
    relationshipType,
  ];
}

class ParentCreateRequested extends ParentEvent {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String relationshipType;

  const ParentCreateRequested({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    required this.relationshipType,
  });

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    surname,
    phoneNumber,
    relationshipType,
  ];
}

class ParentUnlinkRequested extends ParentEvent {
  final String studentId;
  final String parentId;

  const ParentUnlinkRequested({
    required this.studentId,
    required this.parentId,
  });

  @override
  List<Object?> get props => [studentId, parentId];
}
