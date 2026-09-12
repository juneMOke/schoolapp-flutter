import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/enrollment/data/datasources/enrollment_remote_data_source.dart';
import 'package:school_app_flutter/features/enrollment/data/mappers/enrollment_entries_report_mapper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/repositories/enrollment_stats_repository.dart';

class EnrollmentStatsRepositoryImpl implements EnrollmentStatsRepository {
  final EnrollmentRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const EnrollmentStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, EnrollmentStats>> getEnrollmentStats({
    EnrollmentStatsWindow window = const EnrollmentStatsWindow.year(),
  }) async {
    try {
      final response = await remoteDataSource.getEnrollmentStats(
        requiredAuth,
        window.apiPeriod,
        window.apiDate,
        window.apiFrom,
        window.apiTo,
      );
      return Right(response.toEntity());
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
  Future<Either<Failure, PaginatedResponse<DayEnrollmentEntry>>> getEntries({
    required EnrollmentStatsWindow window,
    required int page,
    required int size,
    required EnrollmentEntriesOrder order,
  }) async {
    try {
      final response = await remoteDataSource.getEntries(
        requiredAuth,
        window.apiPeriod,
        window.apiDate,
        window.apiFrom,
        window.apiTo,
        page,
        size,
        order.apiValue,
      );
      return Right(response.toEntity());
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
  Future<Either<Failure, EnrollmentEntriesReport>> getEntriesReport({
    required EnrollmentStatsWindow window,
    required EnrollmentEntriesOrder order,
  }) async {
    try {
      final response = await remoteDataSource.getEntriesReport(
        requiredAuth,
        window.apiPeriod,
        window.apiDate,
        window.apiFrom,
        window.apiTo,
        order.apiValue,
        // ⚠️ **Le délai du client ne convient pas à ce document.** Il est
        // calibré sur des réponses de guichet ; composer le registre d'une
        // année prend plusieurs secondes, et une expiration côté client
        // laisserait le serveur finir pour rien — l'appel suivant tomberait
        // sur le 429 d'un rendu qu'on croirait abandonné.
        Options(receiveTimeout: AppConstants.enrollmentEntriesReportTimeout),
      );
      return EnrollmentEntriesReportMapper.map(response);
    } on DioException catch (e) {
      // ⚠️ **Le message du serveur est l'information utile ici**, et
      // l'intercepteur global l'écrase par une constante. Sur le 400 du
      // plafond, c'est lui qui porte le compte réel de lignes.
      // `EditiqueFailureMapper` sait le retrouver dans un corps parti en
      // octets, et rend le type décidé par l'intercepteur.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Aucune incertitude à lever : le registre n'est pas archivé et ne
      // consomme rien qu'on ait à réconcilier. L'échec se réessaie librement.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
