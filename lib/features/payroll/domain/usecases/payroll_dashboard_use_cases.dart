import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_dashboard_repository.dart';

/// Lit au serveur le tableau de bord de la paie d'un mois.
class GetPayrollDashboardUseCase {
  final PayrollDashboardRepository _repository;

  const GetPayrollDashboardUseCase(this._repository);

  Future<Either<Failure, PayrollDashboard>> call(
    String month, {
    PayrollDashboardFilter filter = PayrollDashboardFilter.all,
    String? query,
  }) => _repository.read(month, filter: filter, query: query);
}
