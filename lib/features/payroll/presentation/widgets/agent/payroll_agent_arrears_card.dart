import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les arriérés de l'agent : un mois validé non soldé par ligne — ce qui en
/// a été perçu, ce qui reste. Toucher un mois l'affiche ; le règlement passe
/// par la fiche d'arriérés, la même que dans le registre.
class PayrollAgentArrearsCard extends StatelessWidget {
  /// `null` : aucun arriéré.
  final PayrollArrearsAgent? arrears;
  final ValueChanged<String> onSelectMonth;

  /// `null` : le compte ne verse pas (lecture) — la fiche s'ouvre quand même.
  final VoidCallback? onSettle;

  const PayrollAgentArrearsCard({
    super.key,
    required this.arrears,
    required this.onSelectMonth,
    required this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final arrears = this.arrears;
    if (arrears == null || arrears.months.isEmpty) {
      return EteeloPanelCard(
        title: l10n.payrollAgentArrearsTitle,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: PayrollTone.paid.color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.payrollAgentArrearsEmpty,
                style: AppTypography.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
    final onSettle = this.onSettle;
    return EteeloPanelCard(
      title: l10n.payrollAgentArrearsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final arrear in arrears.months)
            _ArrearRow(
              arrear: arrear,
              onTap: () => onSelectMonth(arrear.month),
            ),
          if (onSettle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: EteeloButton.secondary(
                label: l10n.payrollAgentArrearsSettle,
                icon: Icons.payments_outlined,
                onPressed: onSettle,
                fullWidth: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrearRow extends StatelessWidget {
  final PayrollArrear arrear;
  final VoidCallback onTap;

  const _ArrearRow({required this.arrear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, arrear.currency);
    final label = PayrollLabels.month(context, arrear.month);
    final detail = [
      l10n.payrollAgentArrearPaid(
        money(arrear.paidInCents),
        money(arrear.line.netInCents),
      ),
      if (arrear.prioritized) l10n.payrollAgentArrearPriority,
    ].join(' · ');
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label[0].toUpperCase() + label.substring(1),
                    style: AppTypography.labelLarge,
                  ),
                  Text(
                    detail,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              money(arrear.dueInCents),
              style: AppTypography.labelLarge.copyWith(
                color: PayrollTone.submitted.ink,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
