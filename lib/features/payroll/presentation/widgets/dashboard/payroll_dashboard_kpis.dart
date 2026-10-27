import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_kpi_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres du mois, **en pavés pleins**, dans la devise affichée :
/// ce que la paie devait coûter, ce qu'il faut réellement payer, ce qui est
/// versé, ce qui reste dû — arriérés des mois validés compris.
///
/// Un sens, une couleur, comme sur les autres tableaux de bord : le prévu est
/// « attendu », le net un décaissement (la marque), le versé « encaissé », le
/// reste « manquant ».
///
/// ⚠️ « Soldés pour le mois » ne compte que le net du mois : un agent qui doit
/// encore un arriéré y figure, alors que sa ligne du tableau dit « Partiel ».
class PayrollDashboardKpis extends StatelessWidget {
  final PayrollDashboard dashboard;
  final PayrollDashboardCurrency section;

  const PayrollDashboardKpis({
    super.key,
    required this.dashboard,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = section.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final forecast = section.forecast;
    final progress = section.progress;
    final gross = forecast.grossInCents;
    final saved = forecast.savedInCents;
    final arrears = dashboard.arrears.fold(
      0,
      (sum, agent) => sum + agent.dueIn(currency),
    );
    final validated = dashboard.isValidated && progress != null;
    final untracked = !dashboard.tracked;
    final net = forecast.netInCents;
    final paidPercent = net == 0 || progress == null
        ? 0
        : (progress.paidInCents * 100 / net).round();
    return Semantics(
      container: true,
      label: l10n.payrollDashKpisA11y,
      child: EteeloKpiBand(
        cards: [
          PayrollKpiCard.of(
            label: l10n.payrollDashPlanned,
            valueText: money(gross),
            icon: Icons.account_balance_wallet_outlined,
            accent: DashboardSense.attendu,
            subline: forecast.employerChargesInCents > 0
                ? (dashboard.isValidated
                      ? l10n.payrollDashEmployerCostCurrent(
                          money(forecast.employerChargesInCents),
                        )
                      : l10n.payrollDashEmployerCost(
                          money(forecast.employerChargesInCents),
                        ))
                : null,
          ),
          PayrollKpiCard.of(
            label: l10n.payrollDashNet,
            valueText: money(net),
            icon: Icons.payments_outlined,
            accent: DashboardSense.marque,
            subline: saved > 0 && gross > 0
                ? l10n.payrollDashLessThanPlanned(
                    money(saved),
                    (saved * 100 / gross).round(),
                  )
                : null,
          ),
          PayrollKpiCard.of(
            label: l10n.payrollDashKpiPaid,
            valueText: validated
                ? money(progress.paidInCents)
                : l10n.payrollNoValue,
            icon: Icons.check_circle_outline,
            accent: DashboardSense.encaisse,
            subline: validated
                ? l10n.payrollDashKpiPaidSubline(
                    paidPercent,
                    progress.settledCount,
                  )
                : untracked
                ? l10n.payrollDashNotTrackedKpi
                : l10n.payrollDashNothingBeforeValidation,
          ),
          // Un mois d'avant la v2 n'est pas une dette : seuls les arriérés
          // des mois suivis restent dus.
          PayrollKpiCard.of(
            label: l10n.payrollDashKpiRemaining,
            valueText: untracked && arrears == 0
                ? l10n.payrollNoValue
                : money(
                    (validated
                            ? progress.outstandingInCents
                            : untracked
                            ? 0
                            : net) +
                        arrears,
                  ),
            icon: Icons.hourglass_bottom,
            accent: DashboardSense.manquant,
            subline: arrears > 0
                ? l10n.payrollDashKpiRemainingSubline(money(arrears))
                : validated
                ? null
                : untracked
                ? l10n.payrollDashNotTrackedKpi
                : l10n.payrollDashKpiRemainingDraft,
          ),
        ],
      ),
    );
  }
}
