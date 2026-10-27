import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner_parts.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_banner.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_circuit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau du livre : ‹ octobre 2026 › et son statut, puis le circuit.
/// Le mois ouvre le sélecteur de mois des registres RH — plus de frise :
/// le mois se lit une seule fois.
class PayrollLedgerHeader extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerHeader({super.key, required this.state});

  /// Les douze mois proposés au sélecteur : ceux qui finissent au mois en
  /// cours, ou, pour un mois plus ancien, ceux qui partent de lui ; jamais
  /// avant le premier mois de paie.
  static String firstPickable(PayrollState state) {
    final window = SchoolDayCalendar.addMonths(state.currentMonth, -11);
    final anchor = state.month.compareTo(window) < 0 ? state.month : window;
    final first = state.snapshot.firstMonth;
    return first != null && first.compareTo(anchor) > 0 ? first : anchor;
  }

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<PayrollCubit>();
    final picked = await pickPresenceMonth(
      context,
      month: state.month,
      firstMonth: firstPickable(state),
      lastMonth: state.currentMonth,
    );
    if (picked != null && !cubit.isClosed) cubit.showMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final view = state.view;
    final month = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceBannerButton(
          icon: Icons.chevron_left,
          tooltip: l10n.presenceMarkPreviousMonth,
          onPressed: state.canStepBack ? () => cubit.stepMonth(-1) : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Flexible : sur téléphone le mois passe à la ligne plutôt que de
        // pousser la flèche suivante hors du bandeau.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payrollTabLedger.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.orDoux,
                  letterSpacing: 1.2,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MonthButton(
                    label: PayrollLabels.month(context, state.month),
                    onPick: () => unawaited(_pick(context)),
                  ),
                  if (view != null) PayrollStatusPill(phase: view.phase),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        PresenceBannerButton(
          icon: Icons.chevron_right,
          tooltip: l10n.presenceMarkNextMonth,
          onPressed: state.isCurrentMonth ? null : () => cubit.stepMonth(1),
        ),
        if (!state.isCurrentMonth) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: cubit.goCurrentMonth,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.payrollAgentOnBanner,
            ),
            child: Text(l10n.presenceMarkCurrentMonth),
          ),
        ],
      ],
    );
    return PayrollBanner(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          month,
          if (view != null) PayrollCircuit(view: view),
        ],
      ),
    );
  }
}

/// Le mois du bandeau, qui ouvre le sélecteur : une icône le dit, la zone
/// d'appui fait 48 dp, et le lecteur d'écran annonce un bouton.
class _MonthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPick;

  const _MonthButton({required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Tooltip(
      message: AppLocalizations.of(context)!.presenceMarkPickMonth,
      child: InkWell(
        onTap: onPick,
        borderRadius: AppRadius.brSm,
        child: TouchTarget(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.payrollAgentOnBanner,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.calendar_month_outlined,
                size: AppSpacing.xl,
                color: AppColors.payrollAgentOnBannerMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
