part of 'student_bloc.dart';

sealed class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class StudentStateReset extends StudentEvent {
  const StudentStateReset();
}

class StudentPersonalInfoUpdateRequested extends StudentEvent {
  final String studentId;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;
  final String birthPlace;
  final String nationality;

  const StudentPersonalInfoUpdateRequested({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    required this.birthPlace,
    required this.nationality,
  });

  @override
  List<Object?> get props => [
        studentId,
        firstName,
        lastName,
        surname,
        dateOfBirth,
        gender,
        birthPlace,
        nationality,
      ];
}

class StudentAddressUpdateRequested extends StudentEvent {
  final String studentId;
  final String city;
  final String district;
  final String municipality;
  final String neighborhood;
  final String address;

  const StudentAddressUpdateRequested({
    required this.studentId,
    required this.city,
    required this.district,
    required this.municipality,
    required this.neighborhood,
    required this.address,
  });

  @override
  List<Object?> get props => [
    studentId,
    city,
    district,
    municipality,
    neighborhood,
    address,
  ];
}

class StudentAcademicInfoUpdateRequested extends StudentEvent {
  final String studentId;
  final String schoolLevelId;
  final String schoolLevelGroupId;

  const StudentAcademicInfoUpdateRequested({
    required this.studentId,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => <Object?>[
    studentId,
    schoolLevelId,
    schoolLevelGroupId,
  ];
}