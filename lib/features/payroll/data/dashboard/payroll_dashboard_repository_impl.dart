import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_api.dart';
import 'package:school_app_flutter/features/payroll/data/dashboard/payroll_dashboard_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_dashboard_repository.dart';

/// Le tableau de bord de la paie : le serveur, et lui seul (règle n° 14).
class PayrollDashboardRepositoryImpl implements PayrollDashboardRepository {
  final PayrollDashboardApi _api;
  final ConnectivityService _connectivity;
  final Map<String, dynamic> _requiredAuth;

  const PayrollDashboardRepositoryImpl({
    required PayrollDashboardApi api,
    required ConnectivityService connectivity,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _connectivity = connectivity,
       _requiredAuth = requiredAuth;

  @override
  Future<Either<Failure, PayrollDashboard>> read(
    String month, {
    PayrollDashboardFilter filter = PayrollDashboardFilter.all,
    String? query,
  }) async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Aucune connexion.'));
    }
    final search = query?.trim();
    try {
      final json = await _api.dashboard(
        _requiredAuth,
        month,
        filter.wire,
        search == null || search.isEmpty ? null : search,
      );
      return Right(PayrollDashboardJson.fromJson(json as Map<String, dynamic>));
    } on DioException catch (e) {
      if (e.error is Failure) return Left(e.error as Failure);
      return e.response == null
          ? const Left(NetworkFailure('Network error occurred'))
          : const Left(ServerFailure('Unexpected response'));
    } catch (_) {
      // Une réponse illisible est une erreur, pas un tableau de bord vide.
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }
}
