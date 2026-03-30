import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';

class StudentDetail extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final Gender gender;
  final String birthPlace;
  final String nationality;
  final String? photoUrl;
  final String city;
  final String district;
  final String commune;
  final String address;
  final SchoolLevel schoolLevel;
  final SchoolLevelGroup schoolLevelGroup;

  const StudentDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    required this.birthPlace,
    required this.nationality,
    this.photoUrl,
    required this.city,
    required this.district,
    required this.commune,
    required this.address,
    required this.schoolLevel,
    required this.schoolLevelGroup,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    gender,
    birthPlace,
    nationality,
    photoUrl,
    city,
    district,
    commune,
    address,
    schoolLevel,
    schoolLevelGroup,
  ];
}
