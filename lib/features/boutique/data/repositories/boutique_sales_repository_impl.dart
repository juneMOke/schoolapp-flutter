import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_api.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_sales_report_mapper.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_sales_page_model.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/stats_bucket_keys.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_report.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sales_repository.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';

/// Les ventes de la période : le serveur, et lui seul.
///
/// Hors ligne, l'erreur réseau s'affiche — aucune photo ne la masque, comme
/// la table des reçus de la caisse.
class BoutiqueSalesRepositoryImpl implements BoutiqueSalesRepository {
  final BoutiqueDashboardApi _api;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;

  const BoutiqueSalesRepositoryImpl({
    required BoutiqueDashboardApi api,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth;

  @override
  Future<Either<Failure, BoutiqueSalesPage>> sales(SalesQuery query) async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Aucune connexion.'));
    }
    try {
      final json = await _api.getSales(
        _requiredAuth,
        StatsBucketKeys.dayKey(query.window.from),
        StatsBucketKeys.dayKey(query.window.to),
        query.academicYearId,
        query.family?.wire,
        query.classId,
        query.page,
        SalesQuery.pageSize,
      );
      return Right(
        BoutiqueSalesPageModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return e.response == null
          ? const Left(NetworkFailure('Network error occurred'))
          : const Left(ServerFailure('Unexpected response'));
    } catch (_) {
      // Une page illisible est une erreur, pas une liste vide.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, BoutiqueSalesReport>> report(SalesQuery query) async {
    try {
      final response = await _api.getSalesReport(
        _requiredAuth,
        StatsBucketKeys.dayKey(query.window.from),
        StatsBucketKeys.dayKey(query.window.to),
        query.academicYearId,
        query.family?.wire,
        query.classId,
        // Le délai de guichet expirerait pendant le rendu, et l'appel suivant
        // tomberait sur le 429 d'un rendu qu'on croirait abandonné.
        Options(receiveTimeout: AppConstants.boutiqueSalesReportTimeout),
      );
      return BoutiqueSalesReportMapper.map(response);
    } on DioException catch (e) {
      // Le message du serveur porte l'information utile — le compte réel de
      // ventes sur le 400 du plafond — et l'intercepteur l'écrase.
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      // Rien à réconcilier : le rapport n'est pas archivé, il se redemande.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
