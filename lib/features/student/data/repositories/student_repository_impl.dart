import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/data/datasources/student_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_academic_info_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_address_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_personal_info_request.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_academic_info.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/repositories/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const StudentRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, StudentDetail>> updateStudentPersonalInfo({
    required String studentId,
    required String firstName,
    required String lastName,
    required String surname,
    required String dateOfBirth,
    required String gender,
    required String birthPlace,
    required String nationality,
  }) async {
    try {
      final model = await remoteDataSource.updateStudentPersonalInfo(
        requiredAuth,
        studentId,
        UpdateStudentPersonalInfoRequest(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          dateOfBirth: dateOfBirth,
          gender: gender,
          birthPlace: birthPlace,
          nationality: nationality,
        ),
      );
      return Right(model.toStudentDetail());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, StudentDetail>> updateStudentAddress({
    required String studentId,
    required String city,
    required String district,
    required String municipality,
    required String neighborhood,
    required String address,
  }) async {
    try {
      final model = await remoteDataSource.updateStudentAddress(
        requiredAuth,
        studentId,
        UpdateStudentAddressRequest(
          city: city,
          district: district,
          municipality: municipality,
          neighborhood: neighborhood,
          address: address,
        ),
      );
      return Right(model.toStudentDetail());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, StudentAcademicInfo>> updateStudentAcademicInfo({
    required String studentId,
    required String schoolLevelId,
    required String schoolLevelGroupId,
  }) async {
    try {
      final model = await remoteDataSource.updateStudentAcademicInfo(
        requiredAuth,
        studentId,
        UpdateStudentAcademicInfoRequest(
          schoolLevelId: schoolLevelId,
          schoolLevelGroupId: schoolLevelGroupId,
        ),
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}