import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où en est le règlement d'un salaire validé : non payé, partiel, différé,
/// soldé — au voile de son sens.
class PayrollSettlementPill extends StatelessWidget {
  final PayrollSettlementStatus status;

  const PayrollSettlementPill({super.key, required this.status});

  static PayrollTone toneOf(PayrollSettlementStatus status) => switch (status) {
    PayrollSettlementStatus.unpaid => PayrollTone.alert,
    PayrollSettlementStatus.partial ||
    PayrollSettlementStatus.deferred => PayrollTone.submitted,
    PayrollSettlementStatus.settled => PayrollTone.paid,
    PayrollSettlementStatus.nothingToPay => PayrollTone.draft,
  };

  static String labelOf(
    AppLocalizations l10n,
    PayrollSettlementStatus status,
  ) => switch (status) {
    PayrollSettlementStatus.unpaid => l10n.payrollSettlementUnpaid,
    PayrollSettlementStatus.partial => l10n.payrollSettlementPartial,
    PayrollSettlementStatus.deferred => l10n.payrollSettlementDeferred,
    PayrollSettlementStatus.settled => l10n.payrollSettlementSettled,
    PayrollSettlementStatus.nothingToPay => l10n.payrollSettlementNothing,
  };

  @override
  Widget build(BuildContext context) {
    final tone = toneOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        labelOf(AppLocalizations.of(context)!, status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(color: tone.ink),
      ),
    );
  }
}
