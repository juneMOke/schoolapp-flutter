import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

class StudentDetailModel {
  final String id;
  final String firstName;
  final String lastName;
  final String surname;
  final String dateOfBirth;
  final String gender;
  final String birthPlace;
  final String nationality;
  final String? photoUrl;
  final String city;
  final String district;
  final String municipality;
  final String address;

  final String schoolLevelId;
  final String schoolLevelGroupId;
  final List<String> parentIds;

  const StudentDetailModel({
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
    required this.municipality,
    required this.address,
    required this.parentIds,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  factory StudentDetailModel.fromJson(Map<String, dynamic> json) =>
      StudentDetailModel(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        surname: json['surname'] as String,
        dateOfBirth: json['dateOfBirth'] as String,
        gender: json['gender'] as String,
        birthPlace: json['birthPlace'] as String,
        nationality: json['nationality'] as String,
        photoUrl: json['photoUrl'] as String?,
        city: json['city'] as String,
        district: json['district'] as String,
        municipality: json['municipality'] as String,
        address: json['address'] as String,
        schoolLevelId: json['schoolLevelId'] as String? ?? '',
        schoolLevelGroupId: json['schoolLevelGroupId'] as String? ?? '',
        parentIds: getParentIds(json),
      );

  static List<String> getParentIds(Map<String, dynamic> json) {
    return (json['parentIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'surname': surname,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'birthPlace': birthPlace,
    'nationality': nationality,
    'photoUrl': photoUrl,
    'city': city,
    'district': district,
    'commune': municipality,
    'address': address,
  };

  StudentDetail toStudentDetail() => StudentDetail(
    id: id,
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    gender: Gender.fromString(gender),
    birthPlace: birthPlace,
    nationality: nationality,
    photoUrl: photoUrl,
    city: city,
    district: district,
    municipality: municipality,
    address: address,
    schoolLevel: SchoolLevel(
      id: schoolLevelId,
      name: '',
      code: '',
      displayOrder: 0,
    ),
    schoolLevelGroup: SchoolLevelGroup(
      id: schoolLevelGroupId,
      name: '',
      code: '',
    ),
  );
}
