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
  final String neighborhood;
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
    required this.neighborhood,
    required this.address,
    required this.parentIds,
    required this.schoolLevelId,
    required this.schoolLevelGroupId,
  });

  factory StudentDetailModel.fromJson(Map<String, dynamic> json) =>
      StudentDetailModel(
        id: _readString(json['id']),
        firstName: _readString(json['firstName']),
        lastName: _readString(json['lastName']),
        surname: _readString(json['surname']),
        dateOfBirth: _readString(json['dateOfBirth']),
        gender: _readString(json['gender']),
        birthPlace: _readString(json['birthPlace']),
        nationality: _readString(json['nationality']),
        photoUrl: _readString(json['photoUrl']),
        city: _readString(json['city']),
        district: _readString(json['district']),
        municipality: _readString(json['municipality']),
        neighborhood: _readString(json['neighborhood']),
        address: _readString(json['address']),
        schoolLevelId: _readString(json['schoolLevelId']),
        schoolLevelGroupId: _readString(json['schoolLevelGroupId']),
        parentIds: getParentIds(json),
      );

  static String _readString(dynamic value) => value?.toString() ?? '';

  static List<String> getParentIds(Map<String, dynamic> json) {
    final parentIds = json['parentIds'];
    if (parentIds is! List) {
      return [];
    }

    return parentIds.map((e) => _readString(e)).toList();
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
    'neighborhood': neighborhood,
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
    neighborhood: neighborhood,
    address: address,
    schoolLevel: SchoolLevel(
      id: schoolLevelId,
      name: '',
      code: '',
      displayOrder: 0,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: SchoolLevelGroup(
      id: schoolLevelGroupId,
      name: '',
      code: '',
    ),
  );
}
