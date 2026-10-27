import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_month_status.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_net_progress.dart';

/// Un mois de la fenêtre glissante. Seul un mois validé de la v2 porte des
/// montants, et le mois affiché s'il n'est pas validé (tout en « pas
/// encore ») ; les autres n'ont que leur état.
class PayrollDashboardMonth extends Equatable {
  /// `YYYY-MM`.
  final String month;
  final PayrollMonthStatus status;
  final bool tracked;

  /// Le net du mois par devise, réparti comme [PayrollNetProgress] (sans
  /// compteurs).
  final Map<String, PayrollNetProgress> byCurrency;

  const PayrollDashboardMonth({
    required this.month,
    required this.status,
    this.tracked = true,
    this.byCurrency = const {},
  });

  /// Validé, et plus rien du net à verser dans aucune devise.
  bool get isFullyPaid =>
      status == PayrollMonthStatus.validated &&
      tracked &&
      byCurrency.isNotEmpty &&
      byCurrency.values.every(
        (progress) =>
            progress.outstandingInCents == 0 && progress.notYetInCents == 0,
      );

  @override
  List<Object?> get props => [month, status, tracked, byCurrency];
}
