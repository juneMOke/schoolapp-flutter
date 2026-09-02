import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_period.dart';
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
  Future<Either<Failure, FinanceRecovery>> getFinanceRecovery() async {
    try {
      final response = await remoteDataSource.getFinanceRecovery(requiredAuth);
      return Right(response.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      // Une charge utile illisible passe par ici : `fromJson` lève sur un
      // `kpis` absent, et l'écran doit dire « erreur », jamais « 0 encaissé ».
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, FinanceTill>> getFinanceTill({
    TillPeriod period = TillPeriod.day,
  }) async {
    try {
      final response = await remoteDataSource.getFinanceTill(
        requiredAuth,
        period.apiValue,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      // `fromJson` lève sur un `summary` absent : mieux vaut dire « erreur »
      // que rendre un tiroir vide à qui l'a ouvert devant lui.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
