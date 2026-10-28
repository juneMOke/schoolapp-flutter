import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_dashboard_months.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_banner.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_banner_month.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête : le bandeau sombre du livre — ‹ mois › (qui ouvre le
/// sélecteur) et son statut, l'instant de la situation — et, de l'autre
/// côté, « Actualiser » et « Ouvrir la paie ». Il reste en place sous un
/// squelette, un vide ou une erreur : le mois doit rester accessible, c'est
/// souvent lui qui fait sortir du vide.
class PayrollDashboardHeader extends StatelessWidget {
  final PayrollDashboardState state;
  final VoidCallback onOpenPayroll;

  const PayrollDashboardHeader({
    super.key,
    required this.state,
    required this.onOpenPayroll,
  });

  /// Les douze mois qui finissent au mois en cours, ou, pour un mois plus
  /// ancien atteint aux flèches, ceux qui partent de lui.
  static String firstPickable(PayrollDashboardState state) {
    final window = PayrollMonth.add(
      state.currentMonth,
      1 - PayrollDashboardMonths.window,
    );
    return state.month.compareTo(window) < 0 ? state.month : window;
  }

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<PayrollDashboardCubit>();
    final picked = await pickPresenceMonth(
      context,
      month: state.month,
      firstMonth: firstPickable(state),
      lastMonth: state.currentMonth,
    );
    if (picked != null && !cubit.isClosed) unawaited(cubit.showMonth(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollDashboardCubit>();
    final dashboard = state.dashboard;
    return PayrollBanner(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PayrollBannerMonth(
                eyebrow: l10n.subMenuDashboard,
                month: state.month,
                phase: dashboard == null
                    ? null
                    : PayrollDashboardMonths.phaseOfShown(dashboard),
                onPrevious: () => unawaited(cubit.stepMonth(-1)),
                onNext: state.isCurrentMonth
                    ? null
                    : () => unawaited(cubit.stepMonth(1)),
                onCurrent: state.isCurrentMonth
                    ? null
                    : () => unawaited(cubit.showMonth(null)),
                onPick: () => unawaited(_pick(context)),
              ),
              if (dashboard != null)
                Padding(
                  // Aligné sous le mois, après la flèche de gauche.
                  padding: const EdgeInsetsDirectional.only(
                    start: AppDimensions.presenceMarkTapTarget + AppSpacing.sm,
                  ),
                  child: Text(
                    [
                      l10n.payrollDashSituationAt(
                        PayrollLabels.day(context, dashboard.situationAt),
                      ),
                      if (dashboard.provisional) l10n.payrollDashProvisional,
                    ].join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.payrollAgentOnBannerMuted,
                    ),
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: state.refreshing
                    ? null
                    : () => unawaited(cubit.refresh()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.payrollDashRefresh),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.payrollAgentOnBanner,
                  disabledForegroundColor: AppColors.payrollAgentOnBannerFaint,
                ),
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
    );
  }
}
