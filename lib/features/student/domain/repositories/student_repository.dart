import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_academic_info.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

abstract class StudentRepository {
  Future<Either<Failure, StudentDetail>> updateStudentPersonalInfo({
    required String studentId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String gender,
    required String birthPlace,
    required String nationality,
  });

  Future<Either<Failure, StudentDetail>> updateStudentAddress({
    required String studentId,
    required String city,
    required String district,
    required String municipality,
    required String neighborhood,
    required String address,
  });

  Future<Either<Failure, StudentAcademicInfo>> updateStudentAcademicInfo({
    required String studentId,
    required String schoolLevelId,
    required String schoolLevelGroupId,
  });
}