class UpdateParentRequest {
  final String firstName;
  final String lastName;
  final String? surname;
  final String email;
  final String phoneNumber;
  final String relationshipType;

  const UpdateParentRequest({
    required this.firstName,
    required this.lastName,
    this.surname,
    required this.email,
    required this.phoneNumber,
    required this.relationshipType,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'email': email,
    'phoneNumber': phoneNumber,
    'relationshipType': relationshipType,
  };
}
