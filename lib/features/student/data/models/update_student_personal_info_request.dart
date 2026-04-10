class UpdateStudentPersonalInfoRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;
  final String birthPlace;
  final String nationality;

  const UpdateStudentPersonalInfoRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    required this.birthPlace,
    required this.nationality,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'birthPlace': birthPlace,
    'nationality': nationality,
  };
}
