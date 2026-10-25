import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La cellule « Versement » : après validation seulement ; le bouton Verser
/// pour l'économe, « À verser » en lecture pour la direction, puis le statut
/// du règlement (B3) — soldé, partiel et son reste, différé et l'arriéré —,
/// « Rien à verser » sur un net nul.
class PayrollPayoutCell extends StatelessWidget {
  final PayrollMonthView view;
  final PayrollLine line;
  final bool canWrite;
  final VoidCallback onPayout;

  const PayrollPayoutCell({
    super.key,
    required this.view,
    required this.line,
    required this.canWrite,
    required this.onPayout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );
    final settlement = view.settlementOf(line);
    final last = settlement.last;
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    final pill = switch (settlement.status) {
      PayrollSettlementStatus.settled => (
        PayrollTone.paid,
        settlement.disbursements.length == 1
            ? PayrollLabels.mode(l10n, last!.mode)
            : l10n.payrollSettledCount(settlement.disbursements.length),
      ),
      PayrollSettlementStatus.partial => (
        PayrollTone.submitted,
        l10n.payrollPartialLeft(money(settlement.remainingInCents)),
      ),
      PayrollSettlementStatus.deferred => (
        PayrollTone.submitted,
        l10n.payrollDeferredLeft(money(settlement.remainingInCents)),
      ),
      _ => null,
    };
    if (pill != null && view.canPay) {
      final (tone, label) = pill;
      return InkWell(
        onTap: onPayout,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: tone.soft,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(color: tone.ink),
                ),
              ),
            ),
            if (last != null) ...[
              const SizedBox(width: AppSpacing.xs),
              RecordSyncDot(state: last.syncState),
            ],
          ],
        ),
      );
    }
    if (!view.canPay) return Text(l10n.payrollPayAfterValidation, style: muted);
    if (line.netInCents <= 0) {
      return Text(l10n.payrollNothingToPay, style: muted);
    }
    if (!canWrite) {
      return Text(
        l10n.payrollToPay,
        style: AppTypography.labelMedium.copyWith(
          color: PayrollTone.submitted.ink,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: EteeloButton.primary(
        label: l10n.payrollPay,
        icon: Icons.payments_outlined,
        size: EteeloButtonSize.compact,
        onPressed: onPayout,
        fullWidth: false,
      ),
    );
  }
}
