import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;
  final Map<String, dynamic> requiredAuth;

  const FinanceRepositoryImpl({
    required this.remoteDataSource,
    required this.requiredAuth,
  });

  @override
  Future<Either<Failure, List<FeeTariff>>> getFeeTariffsByLevel({
    required String levelId,
  }) async {
    try {
      final models = await remoteDataSource.listTariffsByLevel(
        requiredAuth,
        levelId,
      );
      return Right(models.map((m) => m.toEntity()).toList());
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
  Future<Either<Failure, FinanceStats>> getFinanceStats({
    FinanceStatsPeriod period = FinanceStatsPeriod.year,
    String? month,
    String? week,
  }) async {
    try {
      final response = await remoteDataSource.getFinanceStats(
        requiredAuth,
        period.apiValue,
        month,
        week,
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
}
