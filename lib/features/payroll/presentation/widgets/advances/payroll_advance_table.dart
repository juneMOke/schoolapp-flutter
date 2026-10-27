import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_advance_status_pill.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_repayment_bar.dart';
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
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
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
        // Née d'une dépense, l'avance suit sa dépense (B5).
        advance.expenseId == null &&
        !PayrollAdvanceRules.hasFrozenDeduction(snapshot, advance);
    return EteeloColumnTableRow(
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
          style: EteeloColumnTableRow.figures(),
        ),
        Text(
          money(amount),
          textAlign: TextAlign.end,
          style: EteeloColumnTableRow.figures(strong: true),
        ),
        Text(
          l10n.payrollAdvanceSchedule(
            advance.installments,
            money(PayrollMath.floorDiv(amount, advance.installments)),
            PayrollLabels.month(context, advance.firstMonth),
          ),
          style: AppTypography.bodySmall,
        ),
        PayrollRepaymentBar(
          ratio: amount == 0 ? 0 : deducted / amount,
          deducted: l10n.payrollAdvanceDeducted(money(deducted)),
          remaining: l10n.payrollAdvanceRemaining(
            money(advance.remainingInCents),
          ),
        ),
        Row(
          children: [
            Flexible(
              child: PayrollAdvanceStatusPill(status: status, advance: advance),
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
