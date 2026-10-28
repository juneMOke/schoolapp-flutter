import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ce que chaque salarié perçoit » : prévu, retenues, net du mois,
/// arriérés antérieurs, perçu, reste et statut — les lignes et le total
/// servis par le serveur, aux mêmes définitions que son PDF.
class PayrollDashboardStaffTable extends StatelessWidget {
  final PayrollDashboardCurrency section;

  /// Toucher une ligne : la fiche de l'agent ; `null` : lignes inertes.
  final ValueChanged<String>? onOpen;

  const PayrollDashboardStaffTable({
    super.key,
    required this.section,
    this.onOpen,
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
    final rows = section.rows;
    final totals = section.totals;
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
      footer: totals == null ? null : _total(context, totals),
    );
  }

  Widget _row(BuildContext context, PayrollDashboardRow row) {
    final none = AppLocalizations.of(context)!.payrollNoValue;
    String money(int cents) => PayrollLabels.money(cents, section.currency);
    final onOpen = this.onOpen;
    return EteeloColumnTableRow(
      widths: _widths,
      onTap: onOpen == null ? null : () => onOpen(row.staffMemberId),
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.fullName,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge,
            ),
            if (row.jobTitle case final job? when job.isNotEmpty)
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
              ? none
              : '− ${money(row.deductionsInCents)}',
        ),
        _figure(money(row.netInCents), strong: true),
        _figure(
          row.arrearsInCents == 0 ? none : '+ ${money(row.arrearsInCents)}',
        ),
        _figure(money(row.receivedInCents)),
        _figure(money(row.remainingInCents), strong: true),
        _Status(status: row.status),
      ],
    );
  }

  Widget _total(BuildContext context, PayrollDashboardTotals totals) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) => PayrollLabels.money(cents, section.currency);
    final ink = ListingTones.table.headerInk;
    Widget total(String text) => _figure(text, strong: true, color: ink);
    return EteeloColumnTableRow(
      widths: _widths,
      // Le bandeau de l'en-tête, comme le total du livre.
      background: ListingTones.table.header,
      labelInk: ink,
      cells: [
        Text(
          l10n.payrollDashTotal(section.currency),
          style: AppTypography.labelLarge.copyWith(color: ink),
        ),
        total(money(totals.plannedInCents)),
        total('− ${money(totals.deductionsInCents)}'),
        total(money(totals.netInCents)),
        total('+ ${money(totals.arrearsInCents)}'),
        total(money(totals.receivedInCents)),
        total(money(totals.remainingInCents)),
        const SizedBox.shrink(),
      ],
    );
  }

  static Widget _figure(String text, {bool strong = false, Color? color}) =>
      Text(
        text,
        textAlign: TextAlign.end,
        style: EteeloColumnTableRow.figures(color: color, strong: strong),
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
