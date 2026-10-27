import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre jalons du circuit, sur le bandeau sombre du livre — préparée,
/// soumise, validée, versée : faits en vert coché, le courant en terre cuite
/// cerné, les suivants en verre ; le libellé sous la pastille, la date sous
/// soumise et validée. Réduit d'un bloc plutôt que de passer à la ligne sur
/// un téléphone.
class PayrollCircuit extends StatelessWidget {
  final PayrollMonthView view;

  const PayrollCircuit({super.key, required this.view});

  /// Le rang du jalon courant (0 à 3). Un geste en vol n'avance pas le
  /// circuit : il n'est pas encore l'état du serveur.
  static int stepOf(PayrollPhase phase) => switch (phase) {
    PayrollPhase.draft || PayrollPhase.submitting => 0,
    PayrollPhase.submitted ||
    PayrollPhase.returning ||
    PayrollPhase.validating => 1,
    PayrollPhase.validated || PayrollPhase.reopening => 2,
    PayrollPhase.paid => 3,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = stepOf(view.phase);
    final header = view.header;
    final labels = [
      (l10n.payrollCircuitPrepared, null),
      (l10n.payrollCircuitSubmitted, header?.submittedAt),
      (l10n.payrollCircuitValidated, header?.validatedAt),
      (l10n.payrollCircuitPaid, null),
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, (label, date)) in labels.indexed) ...[
            if (index > 0)
              Container(
                width: AppDimensions.payrollCircuitLink,
                height: AppDimensions.presenceMarkBorderWidth,
                margin: const EdgeInsets.only(
                  top: AppDimensions.payrollCircuitDot / 2,
                ),
                color: index <= step
                    ? AppColors.payrollAgentBannerGood
                    : AppColors.payrollAgentOnBannerFaint,
              ),
            _Milestone(
              index: index,
              label: label,
              date: step >= index && date != null
                  ? PayrollLabels.day(context, date)
                  : null,
              done: index < step || (index == 3 && step == 3),
              current: index == step && step < 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  final int index;
  final String label;
  final String? date;
  final bool done;
  final bool current;

  const _Milestone({
    required this.index,
    required this.label,
    required this.date,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.vertSavane
        : current
        ? AppColors.terreCuite
        : AppColors.payrollAgentBannerTile;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimensions.payrollCircuitDot,
            height: AppDimensions.payrollCircuitDot,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: done || current
                  ? null
                  : Border.all(color: AppColors.payrollAgentOnBannerMuted),
              boxShadow: current
                  ? [
                      const BoxShadow(
                        color: AppColors.payrollAgentOnBannerFaint,
                        spreadRadius: AppSpacing.xs,
                      ),
                    ]
                  : null,
            ),
            child: done
                ? const Icon(
                    Icons.check,
                    size: AppSpacing.lg,
                    color: AppColors.payrollAgentOnBanner,
                  )
                : Text(
                    '${index + 1}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.payrollAgentOnBanner,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: done || current
                  ? AppColors.payrollAgentOnBanner
                  : AppColors.payrollAgentOnBannerMuted,
              fontWeight: current ? FontWeight.w700 : null,
            ),
          ),
          if (date != null)
            Text(
              date!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.payrollAgentOnBannerMuted,
              ),
            ),
        ],
      ),
    );
  }
}
