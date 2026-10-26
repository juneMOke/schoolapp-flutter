import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_statement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'état de paie : le tableur des écoles, en mieux — groupé par catégorie,
/// sous-total par groupe, total général, chaque montant à sa colonne. Toucher
/// une ligne ouvre ses éléments variables (brouillon, économe), sinon son
/// bulletin.
class PayrollStatementTable extends StatelessWidget {
  final List<PayrollStatementGroup> groups;
  final ValueChanged<PayrollLine> onOpen;

  const PayrollStatementTable({
    super.key,
    required this.groups,
    required this.onOpen,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColCode,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColCode,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColAmount,
  ];

  /// Les montants d'une ligne, dans l'ordre des colonnes après NJP.
  static List<int> _amounts(PayrollStatementRow row) {
    final d = row.line.deductions;
    return [
      d.absenceInCents,
      row.loanInCents,
      row.salaryAdvanceInCents,
      d.childcareInCents,
      d.iprInCents,
      d.cnssInCents,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget Function(BuildContext)>[
      for (final group in groups) ...[
        (context) => _groupHeader(context, group),
        for (final row in group.rows) (context) => _row(context, row),
        (context) => _total(context, l10n.payrollStatementSubtotal, [
          for (final row in group.rows) row,
        ]),
      ],
    ];
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.payrollStatementMinWidth,
      frozenFirstColumn: true,
      widths: _widths,
      endAligned: const {2, 4, 5, 6, 7, 8, 9, 10},
      headers: [
        l10n.payrollStatementColName,
        l10n.payrollStatementColGrade,
        l10n.payrollStatementColGross,
        l10n.payrollStatementColWorkedDays,
        l10n.payrollStatementColAbsence,
        l10n.payrollStatementColLoan,
        l10n.payrollStatementColAdvance,
        l10n.payrollStatementColChildcare,
        l10n.payrollStatementColIpr,
        l10n.payrollStatementColCnss,
        l10n.payrollStatementColNet,
      ],
      rowCount: items.length,
      row: (context, index) => items[index](context),
      footer: _total(context, l10n.payrollStatementTotal, [
        for (final group in groups) ...group.rows,
      ], grand: true),
    );
  }

  Widget _groupHeader(BuildContext context, PayrollStatementGroup group) {
    final l10n = AppLocalizations.of(context)!;
    final category = group.category;
    return EteeloColumnTableRow(
      widths: _widths,
      background: AppColors.surfaceAlt,
      cells: [
        Text(
          (category == null
                  ? l10n.payrollStatementOther
                  : StaffLabels.category(l10n, category))
              .toUpperCase(),
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        for (var i = 1; i < _widths.length; i++) const SizedBox.shrink(),
      ],
    );
  }

  Widget _row(BuildContext context, PayrollStatementRow row) {
    final line = row.line;
    String money(int cents) =>
        cents == 0 ? '—' : PayrollLabels.money(cents, line.currency);
    Widget figure(String text, {Color? color, bool strong = false}) => Text(
      text,
      textAlign: TextAlign.end,
      style: EteeloColumnTableRow.figures(color: color, strong: strong),
    );
    return EteeloColumnTableRow(
      widths: _widths,
      onTap: () => onOpen(line),
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.member?.fullName ?? line.staffMemberId,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge,
            ),
            if (row.member?.jobTitle case final job? when job.isNotEmpty)
              Text(
                job,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
          ],
        ),
        Text(row.grade ?? '—', style: AppTypography.bodyMedium),
        figure(PayrollLabels.money(line.grossInCents, line.currency)),
        Text(
          '${line.deductions.workedDays ?? '—'}',
          style: AppTypography.bodyMedium,
        ),
        for (final cents in _amounts(row))
          figure(
            money(cents),
            color: cents == 0 ? null : PayrollTone.alert.ink,
          ),
        figure(
          PayrollLabels.money(line.netInCents, line.currency),
          strong: true,
        ),
      ],
    );
  }

  /// Un total par devise : sous-total d'un groupe, ou total général.
  Widget _total(
    BuildContext context,
    String label,
    List<PayrollStatementRow> rows, {
    bool grand = false,
  }) {
    final currencies = {for (final row in rows) row.line.currency}.toList()
      ..sort();
    final ink = grand ? DashboardTones.inkValeur : null;
    Widget figure(String text) => Text(
      text,
      textAlign: TextAlign.end,
      style: EteeloColumnTableRow.figures(color: ink, strong: true),
    );
    String sum(String currency, int Function(PayrollStatementRow) of) =>
        PayrollLabels.money(
          rows
              .where((row) => row.line.currency == currency)
              .fold(0, (total, row) => total + of(row)),
          currency,
        );
    return Column(
      children: [
        for (final currency in currencies)
          EteeloColumnTableRow(
            widths: _widths,
            background: grand
                ? DashboardTones.pave(DashboardSense.attendu)
                : AppColors.surfaceAlt,
            cells: [
              Text(
                '$label · $currency',
                style: AppTypography.labelLarge.copyWith(color: ink),
              ),
              const SizedBox.shrink(),
              figure(sum(currency, (row) => row.line.grossInCents)),
              const SizedBox.shrink(),
              for (var i = 0; i < 6; i++)
                figure(sum(currency, (row) => _amounts(row)[i])),
              figure(sum(currency, (row) => row.line.netInCents)),
            ],
          ),
      ],
    );
  }
}
