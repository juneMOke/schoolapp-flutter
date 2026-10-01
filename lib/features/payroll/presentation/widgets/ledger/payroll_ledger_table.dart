import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_payout_cell.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le livre : une ligne par agent, montants à droite en chiffres tabulaires,
/// ligne de total par devise en pied. Toucher une ligne ouvre ses éléments
/// variables (brouillon, économe), sinon son bulletin.
class PayrollLedgerTable extends StatelessWidget {
  final PayrollMonthView view;
  final PayrollSnapshot snapshot;
  final List<PayrollLine> lines;
  final ValueChanged<PayrollLine> onOpen;
  final ValueChanged<PayrollLine> onPayout;
  final bool canWrite;

  const PayrollLedgerTable({
    super.key,
    required this.view,
    required this.snapshot,
    required this.lines,
    required this.onOpen,
    required this.onPayout,
    required this.canWrite,
  });

  static const List<double?> _widths = [
    null,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAttendance,
    AppDimensions.payrollColPayout,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      minWidth: AppDimensions.payrollLedgerMinWidth,
      widths: _widths,
      endAligned: const {1, 2, 3, 4, 5},
      headers: [
        l10n.payrollColAgent,
        l10n.payrollColBase,
        l10n.payrollColOvertime,
        l10n.payrollColAllowance,
        l10n.payrollColAdvance,
        l10n.payrollColNet,
        l10n.payrollColAttendance,
        l10n.payrollColPayout,
      ],
      rowCount: lines.length,
      row: (context, index) => _row(context, lines[index]),
      footer: _footer(context),
    );
  }

  Widget _row(BuildContext context, PayrollLine line) {
    final l10n = AppLocalizations.of(context)!;
    final member = snapshot.member(line.staffMemberId);
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    Widget amount(String text, {Color? color, bool strong = false}) => Text(
      text,
      textAlign: TextAlign.end,
      style: EteeloColumnTableRow.figures(color: color, strong: strong),
    );
    final carried = line.carriedInCents;
    return EteeloColumnTableRow(
      widths: _widths,
      onTap: () => onOpen(line),
      cells: [
        Row(
          children: [
            if (member != null)
              StaffAvatar(
                member: member,
                sync: member.syncState,
                size: AppDimensions.presenceMarkIconButtonSize,
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member?.fullName ?? line.staffMemberId,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge,
                  ),
                  StaffContractBadge(kind: line.contractKind),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            amount(money(line.baseInCents)),
            if (line.isHourly)
              Text(
                l10n.payrollHoursOf(
                  PayrollLabels.hours(l10n, line.baseMinutes ?? 0),
                  PayrollLabels.month(
                    context,
                    line.hoursMonth ?? PayrollMonth.previous(line.month),
                  ),
                ),
                textAlign: TextAlign.end,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
          ],
        ),
        amount(
          line.overtimeAllowed
              ? money(line.overtimeInCents)
              : l10n.payrollNotApplicable,
          color: line.overtimeAllowed ? null : AppColors.textMutedAa,
        ),
        amount(money(line.allowanceInCents)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            amount(
              line.advanceInCents == 0
                  ? '—'
                  : '− ${money(line.advanceInCents)}',
              color: line.advanceInCents == 0 ? null : PayrollTone.alert.ink,
            ),
            if (carried > 0)
              Text(
                l10n.payrollCarried(money(carried)),
                style: AppTypography.bodySmall.copyWith(
                  color: PayrollTone.submitted.ink,
                ),
              ),
          ],
        ),
        amount(money(line.netInCents), strong: true),
        _Signals(line: line),
        PayrollPayoutCell(
          view: view,
          line: line,
          canWrite: canWrite,
          onPayout: () => onPayout(line),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byCurrency = <String, List<PayrollLine>>{};
    for (final line in lines) {
      (byCurrency[line.currency] ??= []).add(line);
    }
    final currencies = byCurrency.keys.toList()..sort();
    int sum(List<PayrollLine> of, int Function(PayrollLine) amount) =>
        of.fold(0, (total, line) => total + amount(line));
    return Column(
      children: [
        for (final currency in currencies)
          EteeloColumnTableRow(
            widths: _widths,
            background: AppColors.surfaceAlt,
            cells: [
              Text(
                l10n.payrollTotalIn(currency),
                style: AppTypography.labelLarge,
              ),
              for (final amountOf in <int Function(PayrollLine)>[
                (l) => l.baseInCents,
                (l) => l.overtimeInCents,
                (l) => l.allowanceInCents,
                (l) => l.advanceInCents,
                (l) => l.netInCents,
              ])
                Text(
                  PayrollLabels.money(
                    sum(byCurrency[currency]!, amountOf),
                    currency,
                  ),
                  textAlign: TextAlign.end,
                  style: EteeloColumnTableRow.figures(strong: true),
                ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
      ],
    );
  }
}

/// « 1 abs », « 2 ret », ou « RAS » — indicatif, sans retenue.
class _Signals extends StatelessWidget {
  final PayrollLine line;

  const _Signals({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final attendance = line.attendance;
    final parts = [
      if (attendance.unjustifiedAbsences > 0)
        (
          l10n.payrollSignalAbsences(attendance.unjustifiedAbsences),
          PayrollTone.alert.ink,
        ),
      if (attendance.lates > 0)
        (l10n.payrollSignalLates(attendance.lates), PayrollTone.submitted.ink),
    ];
    return Tooltip(
      message: l10n.payrollSignalHint,
      child: Text.rich(
        TextSpan(
          children: parts.isEmpty
              ? [
                  TextSpan(
                    text: l10n.payrollSignalNone,
                    style: const TextStyle(color: AppColors.textMutedAa),
                  ),
                ]
              : [
                  for (final (index, (text, color)) in parts.indexed)
                    TextSpan(
                      text: index == 0 ? text : ' · $text',
                      style: TextStyle(color: color),
                    ),
                ],
        ),
        style: AppTypography.bodySmall,
      ),
    );
  }
}
