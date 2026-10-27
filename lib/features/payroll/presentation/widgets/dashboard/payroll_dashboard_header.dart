import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_dashboard_months.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_strip.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête : ‹ mois › et son statut, « Actualiser » et « Ouvrir la paie »,
/// l'instant de la situation, puis la frise des 12 mois servis. Il reste en
/// place sous un squelette, un vide ou une erreur : le mois doit rester
/// accessible, c'est souvent lui qui fait sortir du vide.
class PayrollDashboardHeader extends StatelessWidget {
  final PayrollDashboardState state;
  final VoidCallback onOpenPayroll;

  const PayrollDashboardHeader({
    super.key,
    required this.state,
    required this.onOpenPayroll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollDashboardCubit>();
    final dashboard = state.dashboard;
    final phase = dashboard == null
        ? null
        : PayrollDashboardMonths.phaseOfShown(dashboard);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PresenceMonthNav(
                  month: state.month,
                  isCurrent: state.isCurrentMonth,
                  onPrevious: () => unawaited(cubit.stepMonth(-1)),
                  onNext: () => unawaited(cubit.stepMonth(1)),
                  onCurrent: () => unawaited(cubit.showMonth(null)),
                ),
                if (phase != null) PayrollStatusPill(phase: phase),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                EteeloButton.ghost(
                  label: l10n.payrollDashRefresh,
                  icon: Icons.refresh_rounded,
                  isLoading: state.refreshing,
                  onPressed: () => unawaited(cubit.refresh()),
                  fullWidth: false,
                ),
                EteeloButton.primary(
                  label: l10n.payrollDashOpenPayroll,
                  icon: Icons.receipt_long_outlined,
                  onPressed: onOpenPayroll,
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ),
        if (dashboard != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              l10n.payrollDashSituationAt(
                PayrollLabels.day(context, dashboard.situationAt),
              ),
              if (dashboard.provisional) l10n.payrollDashProvisional,
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PayrollMonthStrip(
            months: PayrollDashboardMonths.entriesOf(dashboard),
            selected: state.month,
            onSelect: (month) => unawaited(cubit.showMonth(month)),
          ),
        ],
      ],
    );
  }
}
