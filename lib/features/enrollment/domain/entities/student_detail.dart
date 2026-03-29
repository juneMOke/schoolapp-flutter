import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';

class StudentDetail extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final Gender gender;
  final String? placeOfBirth;
  final String? nationality;
  final String? photoUrl;
  final String? city;
  final String? district;
  final String? commune;
  final String? neighborhood;
  final String? addressComplement;
  final EnrollmentDetail? enrollment;

  const StudentDetail({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.dateOfBirth,
    required this.gender,
    this.placeOfBirth,
    this.nationality,
    this.photoUrl,
    this.city,
    this.district,
    this.commune,
    this.neighborhood,
    this.addressComplement,
    this.enrollment,
  });

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    surname,
    dateOfBirth,
    gender,
    placeOfBirth,
    nationality,
    photoUrl,
    city,
    district,
    commune,
    neighborhood,
    addressComplement,
    enrollment,
  ];
}
