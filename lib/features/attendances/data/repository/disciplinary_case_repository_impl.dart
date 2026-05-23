import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/models/create_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/disciplinary_case_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';

class DisciplinaryCaseRepositoryImpl implements DisciplinaryCaseRepository {
  final DisciplinaryCaseRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const DisciplinaryCaseRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<DisciplinaryCaseSummary>>> getDisciplinaryCaseList({
    required String studentId,
    required String academicYearId,
  }) async {
    try {
      final models = await remoteDataSource.fetchDisciplinaryCasesByStudentAndYear(
        requiredAuth,
        studentId,
        academicYearId,
      );
      return Right(models.map((model) => model.toEntity()).toList(growable: false));
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, DisciplinaryCaseDetail>> getDisciplinaryCaseDetail({
    required String caseId,
  }) async {
    try {
      final model = await remoteDataSource.getCaseById(requiredAuth, caseId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, DisciplinaryCaseSummary>> createDisciplinaryCase({
    required String studentId,
    required String studentFirstName,
    required String studentLastName,
    String? studentMiddleName,
    required StudentGender studentGender,
    required DateTime disciplinaryCaseDate,
    required String academicYearId,
    required String title,
    required String content,
  }) async {
    try {
      final model = await remoteDataSource.createCase(
        requiredAuth,
        CreateDisciplinaryCaseRequestModel.fromDomain(
          studentId: studentId,
          studentFirstName: studentFirstName,
          studentLastName: studentLastName,
          studentMiddleName: studentMiddleName,
          studentGender: studentGender,
          disciplinaryCaseDate: disciplinaryCaseDate,
          academicYearId: academicYearId,
          title: title,
          content: content,
        ),
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
