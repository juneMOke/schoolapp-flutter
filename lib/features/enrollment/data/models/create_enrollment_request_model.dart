class CreateEnrollmentRequestModel {
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String birthPlace;
  final String nationality;
  final String gender;

  const CreateEnrollmentRequestModel({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.birthPlace,
    required this.nationality,
    required this.gender,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'dateOfBirth': dateOfBirth,
    'birthPlace': birthPlace,
    'nationality': nationality,
    'gender': gender,
  };
}
