import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_kpi_cards.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres de la file (spec §05) : ce qui attend, ce qui traîne,
/// ce qu'on a déjà relancé, ce qui est accordé mais pas payé.
///
/// Le premier est un montant — **volontairement hors des totaux du tableau de
/// bord** : une demande en attente n'est pas de l'argent sorti. Les trois
/// autres sont des effectifs : on n'additionne pas des retards.
class ExpenseQueueKpiBand extends StatelessWidget {
  final ExpenseQueueView view;

  const ExpenseQueueKpiBand({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final approvedUsd = view.approvedTotal.usdCents;
    return EteeloKpiBand(
      cards: [
        expenseMoneyKpi(
          l10n: l10n,
          label: l10n.expenseQueueStatPending,
          totals: view.pendingTotal,
          accent: AppColors.feeStatusPartialInk,
          accentSoft: AppColors.feeStatusPartialSoft,
          icon: Icons.schedule,
          subline: l10n.expenseQueueStatPendingSub(view.pendingTotal.count),
        ),
        EteeloKpiCardData(
          label: l10n.expenseQueueStatOverdue,
          value: view.overdue,
          accent: AppColors.feeStatusDue,
          accentSoft: AppColors.feeStatusDueSoft,
          icon: Icons.warning_amber_rounded,
          subline: view.overdue == 0
              ? l10n.expenseQueueStatNoOverdue
              : l10n.expenseQueueStatOverdueSub(view.oldestWaitDays),
        ),
        EteeloKpiCardData(
          label: l10n.expenseQueueStatReminded,
          value: view.reminded,
          accent: AppColors.feeStatusPartialInk,
          accentSoft: AppColors.feeStatusPartialSoft,
          icon: Icons.notifications_active_outlined,
          subline: view.reminded == 0
              ? l10n.expenseQueueStatNoReminder
              : l10n.expenseQueueStatRemindedSub,
        ),
        EteeloKpiCardData(
          label: l10n.expenseQueueStatApproved,
          value: view.approvedTotal.count,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          icon: Icons.verified_outlined,
          // Sans taux publié, le montant accordé ne se lit pas en dollars :
          // la carte compte alors les demandes et se tait sur la somme (A5).
          subline: approvedUsd == null
              ? null
              : l10n.expenseQueueStatApprovedSub(
                  ExpenseMoneyText.usd(approvedUsd),
                ),
        ),
      ],
    );
  }
}
