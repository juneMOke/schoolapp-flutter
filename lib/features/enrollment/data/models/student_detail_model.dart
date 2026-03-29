import 'package:school_app_flutter/features/enrollment/data/models/enrollment_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_detail.dart';

class StudentDetailModel {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;
  final String? placeOfBirth;
  final String? nationality;
  final String? photoUrl;
  final String? city;
  final String? district;
  final String? commune;
  final String? neighborhood;
  final String? addressComplement;
  final EnrollmentDetailModel? enrollment;

  const StudentDetailModel({
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

  factory StudentDetailModel.fromJson(Map<String, dynamic> json) =>
      StudentDetailModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        surname: json['surname'] as String,
        dateOfBirth: json['dateOfBirth'] as String,
        gender: json['gender'] as String,
        placeOfBirth: json['placeOfBirth'] as String?,
        nationality: json['nationality'] as String?,
        photoUrl: json['photoUrl'] as String?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        commune: json['commune'] as String?,
        neighborhood: json['neighborhood'] as String?,
        addressComplement: json['addressComplement'] as String?,
        enrollment: json['enrollment'] != null
            ? EnrollmentDetailModel.fromJson(
                json['enrollment'] as Map<String, dynamic>,
              )
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'placeOfBirth': placeOfBirth,
    'nationality': nationality,
    'photoUrl': photoUrl,
    'city': city,
    'district': district,
    'commune': commune,
    'neighborhood': neighborhood,
    'addressComplement': addressComplement,
    'enrollment': enrollment?.toJson(),
  };

  StudentDetail toStudentDetail() => StudentDetail(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    gender: Gender.fromString(gender),
    placeOfBirth: placeOfBirth,
    nationality: nationality,
    photoUrl: photoUrl,
    city: city,
    district: district,
    commune: commune,
    neighborhood: neighborhood,
    addressComplement: addressComplement,
    enrollment: enrollment?.toEnrollmentDetail(),
  );
}
