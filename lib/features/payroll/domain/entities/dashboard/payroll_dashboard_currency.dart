import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_forecast.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_row.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_totals.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_net_progress.dart';

/// Une devise du mois : jamais de conversion, une section chacune.
class PayrollDashboardCurrency extends Equatable {
  final String currency;
  final PayrollDashboardForecast forecast;

  /// Arriérés marqués « en priorité » à verser avec ce mois.
  final int priorityArrearsInCents;

  /// `null` pour un mois validé avant la v2.
  final PayrollNetProgress? progress;

  /// Les lignes que gardent le filtre et la recherche, par nom ; vides pour un
  /// mois validé avant la v2.
  final List<PayrollDashboardRow> rows;

  /// La somme de [rows] ; `null` avec elles.
  final PayrollDashboardTotals? totals;

  const PayrollDashboardCurrency({
    required this.currency,
    this.forecast = const PayrollDashboardForecast(),
    this.priorityArrearsInCents = 0,
    this.progress,
    this.rows = const [],
    this.totals,
  });

  @override
  List<Object?> get props => [
    currency,
    forecast,
    priorityArrearsInCents,
    progress,
    rows,
    totals,
  ];
}
