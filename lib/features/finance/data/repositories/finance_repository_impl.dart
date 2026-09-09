import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/mappers/till_report_mapper.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_recovery.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipts_page.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_report.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_window.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';

/// Le délai que le contrat du rapport recommande. Voir
/// [FinanceRepositoryImpl.getTillReceiptsReport].
const Duration _reportTimeout = Duration(seconds: 60);

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
    TillWindow window = const TillWindow.day(),
  }) async {
    try {
      final response = await remoteDataSource.getFinanceTill(
        requiredAuth,
        window.apiPeriod,
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
      // `fromJson` lève sur un `summary` absent : mieux vaut dire « erreur »
      // que rendre un tiroir vide à qui l'a ouvert devant lui.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, TillReceiptsPage>> getTillReceipts({
    TillWindow window = const TillWindow.day(),
    int page = 0,
    int size = TillReceiptsQuery.defaultPageSize,
  }) async {
    try {
      final response = await remoteDataSource.getTillReceipts(
        requiredAuth,
        window.apiPeriod,
        page,
        size,
        window.apiFrom,
        window.apiTo,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      // Le 403 remonte **tel quel** : c'est un droit manquant, pas une panne,
      // et l'écran doit pouvoir les distinguer pour garder ses cartes.
      if (e.error is Failure) {
        return Left(e.error as Failure);
      }
      return const Left(NetworkFailure('Network error occurred'));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, TillReport>> getTillReceiptsReport({
    TillWindow window = const TillWindow.day(),
  }) async {
    try {
      final response = await remoteDataSource.getTillReceiptsReport(
        requiredAuth,
        window.apiPeriod,
        window.apiFrom,
        window.apiTo,
        // ⚠️ **Le délai du client ne convient pas à ce document.** 12 s sont
        // calibrés sur des réponses de guichet ; ce rendu prend plusieurs
        // secondes sur une grosse fenêtre, et une expiration côté client
        // laisserait le serveur finir son travail pour rien — l'appel suivant
        // tomberait sur le 429 d'un rendu qu'on croirait abandonné.
        Options(receiveTimeout: _reportTimeout),
      );
      return TillReportMapper.map(response);
    } on DioException catch (e) {
      // ⚠️ **Le message du serveur est l'information utile ici**, et
      // l'intercepteur global l'écrase par une constante. Sur le 400 du
      // plafond, c'est lui qui porte le compte réel de lignes — sans quoi
      // l'écran ne pourrait dire que « resserrez », sans dire de combien.
      // `EditiqueFailureMapper` sait le retrouver dans un corps parti en
      // octets, et rend le type décidé par l'intercepteur.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Aucune incertitude à lever : le rapport n'est pas archivé et ne
      // consomme rien qu'on ait à réconcilier. L'échec se réessaie librement.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
