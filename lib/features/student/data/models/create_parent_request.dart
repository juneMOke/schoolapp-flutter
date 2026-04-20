class CreateParentRequest {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? surname;
  final String phoneNumber;
  final String relationshipType;

  const CreateParentRequest({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.phoneNumber,
    required this.relationshipType,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentId': studentId,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'phoneNumber': phoneNumber,
    'relationshipType': relationshipType,
  };
}
