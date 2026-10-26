import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_currency.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_month.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_month_status.dart';

export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_advance.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_arrears.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_currency.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_filter.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_forecast.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_month.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_row.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_totals.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_month_status.dart';
export 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_net_progress.dart';

/// Le tableau de bord de la paie d'un mois, **calculé par le serveur** sur la
/// lecture même de la situation de paie : chiffres, liste et PDF sur les mêmes
/// paramètres (règle n° 14). En centimes, une section par devise.
class PayrollDashboard extends Equatable {
  /// `YYYY-MM`.
  final String month;
  final PayrollMonthStatus status;

  /// Instant ISO de la validation.
  final String? validatedAt;

  /// Vrai tant que la paie n'est pas validée : recalculée, tout « à verser ».
  final bool provisional;

  /// Instant ISO du calcul : arriérés, versements et avances de cet instant.
  final String situationAt;

  /// Faux pour un mois validé avant la v2 — ni répartition ni lignes.
  final bool tracked;
  final List<PayrollDashboardCurrency> currencies;

  /// Les mois de la fenêtre glissante qui ont une paie, du plus ancien au
  /// plus récent.
  final List<PayrollDashboardMonth> months;
  final List<PayrollDashboardAdvance> advances;
  final List<PayrollDashboardArrears> arrears;

  const PayrollDashboard({
    required this.month,
    required this.status,
    required this.situationAt,
    this.validatedAt,
    this.provisional = true,
    this.tracked = true,
    this.currencies = const [],
    this.months = const [],
    this.advances = const [],
    this.arrears = const [],
  });

  bool get isValidated => status == PayrollMonthStatus.validated;

  /// Rien à montrer : aucune paie ouverte, aucun brut calculé, ni arriéré ni
  /// avance. Jugé sur ce que filtre et recherche ne touchent pas — des lignes
  /// filtrées à zéro laissent l'écran, et son vide de tableau en sortie.
  bool get isEmpty =>
      status == PayrollMonthStatus.none &&
      currencies.every((section) => section.forecast.grossInCents == 0) &&
      arrears.every((agent) => agent.dues.isEmpty) &&
      advances.isEmpty;

  /// La section d'une devise, ou la première.
  PayrollDashboardCurrency? section(String? currency) {
    for (final section in currencies) {
      if (section.currency == currency) return section;
    }
    return currencies.isEmpty ? null : currencies.first;
  }

  @override
  List<Object?> get props => [
    month,
    status,
    validatedAt,
    provisional,
    situationAt,
    tracked,
    currencies,
    months,
    advances,
    arrears,
  ];
}
