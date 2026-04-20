import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/data/datasources/parent_remote_data_source.dart';
import 'package:school_app_flutter/features/student/data/models/create_parent_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_parent_request.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const ParentRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, ParentSummary>> updateParent({
    required String parentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String email,
    required String phoneNumber,
    required String relationshipType,
  }) async {
    try {
      final model = await remoteDataSource.updateParent(
        requiredAuth,
        parentId,
        UpdateParentRequest(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          email: email,
          phoneNumber: phoneNumber,
          relationshipType: relationshipType,
        ),
      );
      return Right(model.toParentSummary());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ParentSummary>> createParent({
    required String studentId,
    required String firstName,
    required String lastName,
    required String? surname,
    required String phoneNumber,
    required String relationshipType,
  }) async {
    try {
      final model = await remoteDataSource.createParent(
        requiredAuth,
        CreateParentRequest(
          studentId: studentId,
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          phoneNumber: phoneNumber,
          relationshipType: relationshipType,
        ),
      );
      return Right(model.toParentSummary());
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkParent({
    required String studentId,
    required String parentId,
  }) async {
    try {
      await remoteDataSource.unlinkParent(requiredAuth, studentId, parentId);
      return const Right(null);
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
