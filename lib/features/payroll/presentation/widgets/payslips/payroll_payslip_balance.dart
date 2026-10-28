import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le solde du bulletin sur fond sombre : net du mois, déjà perçu, reste à
/// percevoir — en ligne, filets entre eux, empilés sur un téléphone —, puis
/// la barre de ce qui est réglé.
class PayrollPayslipBalanceCard extends StatelessWidget {
  final PayslipBalance balance;

  const PayrollPayslipBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cells = [
      _Cell(label: l10n.payrollSettleNet, value: balance.net),
      _Cell(
        label: l10n.payrollPayslipBalancePaid,
        value: balance.paid,
        note: balance.paidNote,
        ink: AppColors.payrollAgentBannerGood,
      ),
      _Cell(
        label: l10n.payrollPayslipBalanceRest,
        value: balance.rest,
        note: balance.restNote,
        ink: balance.restNote == null
            ? AppColors.payrollAgentBannerGood
            : AppColors.orDoux,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.bleuProfond,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <
                  AppBreakpoints.payrollPayslipBalanceRowMin) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, cell) in cells.indexed) ...[
                      if (index > 0)
                        const Divider(
                          height: AppSpacing.lg,
                          color: AppColors.payrollAgentOnBannerFaint,
                        ),
                      cell,
                    ],
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, cell) in cells.indexed) ...[
                      if (index > 0)
                        const VerticalDivider(
                          width: AppSpacing.lg,
                          color: AppColors.payrollAgentOnBannerFaint,
                        ),
                      Expanded(child: cell),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: LinearProgressIndicator(
              value: balance.ratio,
              minHeight: AppSpacing.sm,
              color: AppColors.payrollAgentBannerGood,
              backgroundColor: AppColors.payrollAgentOnBannerFaint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            balance.ratioLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.payrollAgentOnBannerMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color ink;

  const _Cell({
    required this.label,
    required this.value,
    this.note,
    this.ink = AppColors.payrollAgentOnBanner,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.payrollAgentOnBannerMuted,
    );
    final note = this.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.payrollAgentOnBannerMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Un montant ne se coupe jamais : il rétrécit plutôt.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (note != null) Text(note, style: muted),
      ],
    );
  }
}
