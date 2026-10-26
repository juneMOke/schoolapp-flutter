import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ce que chaque salarié perçoit » (spec TB 2) : prévu, retenues, net du
/// mois, arriérés antérieurs, perçu, reste et statut — les mêmes colonnes,
/// aux mêmes définitions, que le PDF du serveur. Une ligne Total par devise.
class PayrollDashboardStaffTable extends StatelessWidget {
  final List<PayrollDashboardRow> rows;
  final PayrollSnapshot snapshot;

  const PayrollDashboardStaffTable({
    super.key,
    required this.rows,
    required this.snapshot,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColStatus,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencies = {for (final row in rows) row.currency}.toList()..sort();
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.payrollDashStaffMinWidth,
      widths: _widths,
      endAligned: const {1, 2, 3, 4, 5, 6},
      headers: [
        l10n.payrollColAgent,
        l10n.payrollDashColPlanned,
        l10n.payrollDashColDeductions,
        l10n.payrollDashColNet,
        l10n.payrollDashColArrears,
        l10n.payrollDashColReceived,
        l10n.payrollDashColRemaining,
        l10n.payrollAdvanceColStatus,
      ],
      rowCount: rows.length,
      row: (context, index) => _row(context, rows[index]),
      footer: Column(
        children: [
          for (final currency in currencies)
            _total(
              context,
              currency,
              rows.where((row) => row.currency == currency),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PayrollDashboardRow row) {
    final member = snapshot.member(row.staffMemberId);
    String money(int cents) => PayrollLabels.money(cents, row.currency);
    return EteeloColumnTableRow(
      widths: _widths,
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member?.fullName ?? row.staffMemberId,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge,
            ),
            if (member?.jobTitle case final job? when job.isNotEmpty)
              Text(
                job,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
          ],
        ),
        _figure(money(row.plannedInCents)),
        _figure(
          row.deductionsInCents == 0
              ? '—'
              : '− ${money(row.deductionsInCents)}',
        ),
        _figure(money(row.netInCents), strong: true),
        _figure(
          row.arrearsInCents == 0 ? '—' : '+ ${money(row.arrearsInCents)}',
        ),
        _figure(money(row.receivedInCents)),
        _figure(money(row.remainingInCents), strong: true),
        _Status(status: row.status),
      ],
    );
  }

  Widget _total(
    BuildContext context,
    String currency,
    Iterable<PayrollDashboardRow> rows,
  ) {
    final l10n = AppLocalizations.of(context)!;
    int sum(int Function(PayrollDashboardRow row) of) =>
        rows.fold(0, (total, row) => total + of(row));
    String money(int cents) => PayrollLabels.money(cents, currency);
    return EteeloColumnTableRow(
      widths: _widths,
      background: AppColors.surfaceAlt,
      cells: [
        Text(l10n.payrollDashTotal(currency), style: AppTypography.labelLarge),
        _figure(money(sum((r) => r.plannedInCents)), strong: true),
        _figure('− ${money(sum((r) => r.deductionsInCents))}', strong: true),
        _figure(money(sum((r) => r.netInCents)), strong: true),
        _figure('+ ${money(sum((r) => r.arrearsInCents))}', strong: true),
        _figure(money(sum((r) => r.receivedInCents)), strong: true),
        _figure(money(sum((r) => r.remainingInCents)), strong: true),
        const SizedBox.shrink(),
      ],
    );
  }

  static Widget _figure(String text, {bool strong = false}) => Text(
    text,
    textAlign: TextAlign.end,
    style: EteeloColumnTableRow.figures(strong: strong),
  );
}

class _Status extends StatelessWidget {
  final PayrollDashboardStatus status;

  const _Status({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (status) {
      PayrollDashboardStatus.toDisburse => (
        l10n.payrollDashStatusToDisburse,
        PayrollTone.draft,
      ),
      PayrollDashboardStatus.settled => (
        l10n.payrollDashStatusSettled,
        PayrollTone.paid,
      ),
      PayrollDashboardStatus.partial => (
        l10n.payrollDashStatusPartial,
        PayrollTone.submitted,
      ),
      PayrollDashboardStatus.due => (
        l10n.payrollDashStatusDue,
        PayrollTone.alert,
      ),
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: tone.ink),
          ),
        ),
      ),
    );
  }
}
