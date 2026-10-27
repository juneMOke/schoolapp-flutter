import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';

/// Le tableau de bord de la paie : le serveur, et lui seul. Hors ligne,
/// l'erreur réseau s'affiche — aucune photo locale ne la masque.
abstract class PayrollDashboardRepository {
  Future<Either<Failure, PayrollDashboard>> read(
    String month, {
    PayrollDashboardFilter filter = PayrollDashboardFilter.all,
    String? query,
  });
}
