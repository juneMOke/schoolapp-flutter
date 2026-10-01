import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Le registre des avances : agent et motif, date, montant, échéancier,
/// remboursement (barre or → vert), statut.
class PayrollAdvanceTable extends StatelessWidget {
  final List<SalaryAdvance> advances;
  final PayrollSnapshot snapshot;
  final PayrollMonthView view;

  /// `null` : la session ne peut rien annuler.
  final ValueChanged<SalaryAdvance>? onCancel;

  const PayrollAdvanceTable({
    super.key,
    required this.advances,
    required this.snapshot,
    required this.view,
    required this.onCancel,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColDate,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColSchedule,
    AppDimensions.payrollColSchedule,
    AppDimensions.payrollColStatus,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StaffTable(
      minWidth: AppDimensions.payrollAdvancesMinWidth,
      widths: _widths,
      endAligned: const {2},
      headers: [
        l10n.payrollColAgent,
        l10n.payrollAdvanceColGranted,
        l10n.payrollAdvanceColAmount,
        l10n.payrollAdvanceColSchedule,
        l10n.payrollAdvanceColRepayment,
        l10n.payrollAdvanceColStatus,
      ],
      rowCount: advances.length,
      row: (context, index) => _row(context, advances[index]),
    );
  }

  Widget _row(BuildContext context, SalaryAdvance advance) {
    final l10n = AppLocalizations.of(context)!;
    final member = snapshot.member(advance.staffMemberId);
    final currency = advance.amount.currency;
    String money(int cents) => PayrollLabels.money(cents, currency);
    final amount = advance.amount.amountInCents;
    final deducted = amount - advance.remainingInCents;
    final status = PayrollAdvanceRules.statusOf(advance, view, snapshot);
    final cancellable =
        onCancel != null &&
        advance.isLive &&
        !PayrollAdvanceRules.hasFrozenDeduction(snapshot, advance);
    return StaffTableRow(
      widths: _widths,
      cells: [
        Row(
          children: [
            if (member != null)
              StaffAvatar(
                member: member,
                sync: advance.syncState,
                size: AppDimensions.presenceMarkIconButtonSize,
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member?.fullName ?? advance.staffMemberId,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge,
                  ),
                  Text(
                    '${PayrollLabels.reason(l10n, advance.reason)} · '
                    '${PayrollLabels.mode(l10n, advance.mode)}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          PayrollLabels.day(context, advance.grantedOn),
          style: StaffTableRow.figures(),
        ),
        Text(
          money(amount),
          textAlign: TextAlign.end,
          style: StaffTableRow.figures(strong: true),
        ),
        Text(
          l10n.payrollAdvanceSchedule(
            advance.installments,
            money(PayrollMath.floorDiv(amount, advance.installments)),
            PayrollLabels.month(context, advance.firstMonth),
          ),
          style: AppTypography.bodySmall,
        ),
        _Repayment(
          ratio: amount == 0 ? 0 : deducted / amount,
          deducted: l10n.payrollAdvanceDeducted(money(deducted)),
          remaining: l10n.payrollAdvanceRemaining(
            money(advance.remainingInCents),
          ),
        ),
        Row(
          children: [
            Flexible(
              child: _StatusPill(status: status, advance: advance),
            ),
            if (advance.syncState != RecordSyncState.synced)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: RecordSyncDot(state: advance.syncState),
              ),
            if (cancellable)
              IconButton(
                tooltip: l10n.payrollAdvanceCancel,
                icon: const Icon(Icons.undo, size: AppSpacing.lg),
                onPressed: () => onCancel!(advance),
              ),
          ],
        ),
      ],
    );
  }
}

class _Repayment extends StatelessWidget {
  final double ratio;
  final String deducted;
  final String remaining;

  const _Repayment({
    required this.ratio,
    required this.deducted,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: AppRadius.brPill,
        child: LinearProgressIndicator(
          value: ratio.clamp(0, 1),
          minHeight: AppDimensions.payrollProgressHeight,
          backgroundColor: AppColors.surfaceAlt,
          color: ratio >= 1 ? AppColors.vertSavane : AppColors.orDoux,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '$deducted · $remaining',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  final SalaryAdvanceStatus status;
  final SalaryAdvance advance;

  const _StatusPill({required this.status, required this.advance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (status.phase) {
      SalaryAdvancePhase.refused => (
        l10n.payrollAdvanceStatusRefused,
        PayrollTone.alert,
      ),
      SalaryAdvancePhase.cancelled => (
        l10n.payrollAdvanceStatusCancelled,
        PayrollTone.draft,
      ),
      SalaryAdvancePhase.settled => (
        l10n.payrollAdvanceStatusSettled,
        PayrollTone.paid,
      ),
      SalaryAdvancePhase.upcoming => (
        l10n.payrollAdvanceStatusUpcoming,
        PayrollTone.validated,
      ),
      SalaryAdvancePhase.carried => (
        l10n.payrollAdvanceStatusCarried,
        PayrollTone.alert,
      ),
      SalaryAdvancePhase.running => (
        l10n.payrollAdvanceStatusInstallment(status.rank, advance.installments),
        PayrollTone.submitted,
      ),
    };
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
        label,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(color: tone.ink),
      ),
    );
  }
}
