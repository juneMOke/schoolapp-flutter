import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';

enum PayrollDashboardLoad { loading, ready, failure }

/// Le tableau de bord de la paie : le mois, le filtre et la recherche
/// demandés, et ce que le serveur a répondu.
class PayrollDashboardState extends Equatable {
  final PayrollDashboardLoad load;
  final PayrollDashboard? dashboard;
  final Failure? failure;

  /// `YYYY-MM`.
  final String month;

  /// `YYYY-MM` — le mois du jour : on ne demande jamais au-delà.
  final String currentMonth;
  final PayrollDashboardFilter filter;
  final String search;

  /// La devise choisie quand le mois en compte plusieurs ; `null` : la
  /// première servie.
  final String? currency;

  /// Une relecture est en vol pendant qu'un écran est affiché (filtre,
  /// recherche, F5) : le tableau se grise sans clignoter.
  final bool refreshing;

  /// Le dernier échec d'une relecture qui a gardé l'écran, et son numéro :
  /// l'écran l'annonce une fois par échec.
  final Failure? refreshFailure;
  final int refreshFailureSeq;

  const PayrollDashboardState({
    required this.month,
    required this.currentMonth,
    this.load = PayrollDashboardLoad.loading,
    this.dashboard,
    this.failure,
    this.filter = PayrollDashboardFilter.all,
    this.search = '',
    this.currency,
    this.refreshing = false,
    this.refreshFailure,
    this.refreshFailureSeq = 0,
  });

  bool get isCurrentMonth => month == currentMonth;

  bool get hasRowFilters =>
      filter != PayrollDashboardFilter.all || search.trim().isNotEmpty;

  /// La section de la devise affichée.
  PayrollDashboardCurrency? get section => dashboard?.section(currency);

  PayrollDashboardState copyWith({
    PayrollDashboardLoad? load,
    PayrollDashboard? Function()? dashboard,
    Failure? Function()? failure,
    String? month,
    PayrollDashboardFilter? filter,
    String? search,
    String? Function()? currency,
    bool? refreshing,
    Failure? Function()? refreshFailure,
    int? refreshFailureSeq,
  }) => PayrollDashboardState(
    load: load ?? this.load,
    dashboard: dashboard == null ? this.dashboard : dashboard(),
    failure: failure == null ? this.failure : failure(),
    month: month ?? this.month,
    currentMonth: currentMonth,
    filter: filter ?? this.filter,
    search: search ?? this.search,
    currency: currency == null ? this.currency : currency(),
    refreshing: refreshing ?? this.refreshing,
    refreshFailure: refreshFailure == null
        ? this.refreshFailure
        : refreshFailure(),
    refreshFailureSeq: refreshFailureSeq ?? this.refreshFailureSeq,
  );

  @override
  List<Object?> get props => [
    load,
    dashboard,
    failure,
    month,
    currentMonth,
    filter,
    search,
    currency,
    refreshing,
    refreshFailure,
    refreshFailureSeq,
  ];
}
