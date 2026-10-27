import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_strip.dart';

/// Les mois du tableau de bord, lus sur la réponse du serveur : la fenêtre
/// glissante de 12 mois jusqu'au mois affiché.
abstract final class PayrollDashboardMonths {
  static const int window = 12;

  /// La teinte d'un mois servi : « versée » quand plus rien du net n'est dû.
  static PayrollPhase? phaseOf(PayrollDashboardMonth? month) =>
      switch (month?.status) {
        null || PayrollMonthStatus.none => null,
        PayrollMonthStatus.draft => PayrollPhase.draft,
        PayrollMonthStatus.submitted => PayrollPhase.submitted,
        PayrollMonthStatus.validated =>
          month!.isFullyPaid ? PayrollPhase.paid : PayrollPhase.validated,
      };

  /// Les 12 mois jusqu'au mois affiché, chacun à son statut servi ; un mois
  /// absent de la réponse n'a pas de paie.
  static List<PayrollMonthEntry> entriesOf(PayrollDashboard dashboard) {
    final byMonth = {for (final m in dashboard.months) m.month: m};
    final start = PayrollMonth.add(dashboard.month, 1 - window);
    return [
      for (var i = 0; i < window; i++)
        (
          month: PayrollMonth.add(start, i),
          phase: phaseOf(byMonth[PayrollMonth.add(start, i)]),
        ),
    ];
  }

  /// Le statut du mois affiché, en phase de pastille.
  static PayrollPhase? phaseOfShown(PayrollDashboard dashboard) {
    for (final month in dashboard.months) {
      if (month.month == dashboard.month) return phaseOf(month);
    }
    return phaseOf(
      PayrollDashboardMonth(month: dashboard.month, status: dashboard.status),
    );
  }
}
