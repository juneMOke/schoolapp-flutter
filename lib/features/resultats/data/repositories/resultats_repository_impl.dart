import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/data/datasources/resultats_remote_data_source.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';

class ResultatsRepositoryImpl implements ResultatsRepository {
  final ResultatsRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const ResultatsRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, ResultatsClasse>> getResultatsClasse(
    String classroomId,
    String periodeScolaireId,
    double? seuil,
  ) async {
    try {
      final model = await remoteDataSource.getResultatsClasse(
        requiredAuth,
        classroomId,
        periodeScolaireId,
        seuil,
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

  @override
  Future<Either<Failure, ResultatFocus>> getResultatFocus(
    String classroomId,
    String periodeScolaireId,
    String studentId,
  ) async {
    try {
      final model = await remoteDataSource.getResultatFocus(
        requiredAuth,
        studentId,
        classroomId,
        periodeScolaireId,
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

  @override
  Future<Either<Failure, List<ClassroomMember>>> searchRoster(
    String classroomId,
    String academicYearId,
    String? nom,
    String? postnom,
    String? prenom,
  ) async {
    try {
      final models = await remoteDataSource.searchRoster(
        requiredAuth,
        classroomId,
        academicYearId,
        nom,
        postnom,
        prenom,
      );
      return Right(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
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
  Future<Either<Failure, List<PeriodeScolaire>>> getPeriodesScolaires(
    String classroomId,
  ) async {
    try {
      final models = await remoteDataSource.getPeriodesScolaires(
        requiredAuth,
        classroomId,
      );
      return Right(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
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
