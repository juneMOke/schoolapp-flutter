import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
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
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_cells.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_payout_cell.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_avatar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le livre : une ligne par agent, montants à droite en chiffres tabulaires,
/// ligne de total par devise en pied, du ton de l'en-tête. Toucher une ligne ouvre la fiche de
/// l'agent, comme l'œil de fin de ligne ; en brouillon, le crayon à côté
/// ouvre directement ses éléments variables — la saisie du mois reste d'un
/// seul geste. La colonne du versement prend la place qui reste : l'agent ne
/// s'étire plus loin de ses montants sur un grand écran.
class PayrollLedgerTable extends StatelessWidget {
  final PayrollMonthView view;
  final PayrollSnapshot snapshot;
  final List<PayrollLine> lines;
  final ValueChanged<PayrollLine> onOpen;
  final ValueChanged<PayrollLine> onPayout;

  /// `null` : pas de crayon (paie verrouillée, ou compte sans écriture).
  final ValueChanged<PayrollLine>? onEdit;
  final bool canWrite;

  const PayrollLedgerTable({
    super.key,
    required this.view,
    required this.snapshot,
    required this.lines,
    required this.onOpen,
    required this.onPayout,
    required this.onEdit,
    required this.canWrite,
  });

  static const int _netColumn = 5;

  static const List<double?> _widths = [
    AppDimensions.payrollColAgent,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColSmallAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAttendance,
    null,
    AppDimensions.payrollColOpen,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      tone: ListingTones.table,
      cardsBelow: AppBreakpoints.dataTableCardsMax,
      minWidth: AppDimensions.payrollLedgerMinWidth,
      // Sur une tablette en portrait, le livre défile de côté : l'agent reste
      // à l'écran pendant que ses montants passent.
      frozenFirstColumn: true,
      // Le livre mis en avant, et un filet entre les montants (jusqu'au net)
      // et ce qui les commente : pointage, versement.
      raised: true,
      ruleAfter: _netColumn,
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
        '',
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
    final withheld = line.deductions.totalInCents + line.advanceInCents;
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
              withheld == 0 ? '—' : '− ${money(withheld)}',
              color: withheld == 0 ? null : PayrollTone.alert.ink,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            amount(money(line.netInCents), strong: true),
            if (line.deferredInCents > 0)
              Text(
                line.payout?.fixed ?? false
                    ? l10n.payrollLineToPayFixed(money(line.toPayInCents))
                    : l10n.payrollLineToPay(money(line.toPayInCents)),
                textAlign: TextAlign.end,
                style: AppTypography.bodySmall.copyWith(
                  color: PayrollTone.submitted.ink,
                ),
              ),
          ],
        ),
        PayrollLedgerSignals(line: line),
        PayrollPayoutCell(
          view: view,
          line: line,
          canWrite: canWrite,
          onPayout: () => onPayout(line),
        ),
        PayrollLedgerOpenCell(
          onOpen: () => onOpen(line),
          onEdit: onEdit == null ? null : () => onEdit!(line),
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
    final tone = ListingTones.table;
    return Column(
      children: [
        for (final currency in currencies)
          EteeloColumnTableRow(
            widths: _widths,
            // Le bandeau de l'en-tête, repris en pied : le total ferme le
            // tableau comme l'en-tête l'ouvre.
            background: tone.header,
            labelInk: tone.headerInk,
            cells: [
              Text(
                l10n.payrollTotalIn(currency),
                style: AppTypography.labelLarge.copyWith(color: tone.headerInk),
              ),
              for (final amountOf in <int Function(PayrollLine)>[
                (l) => l.baseInCents,
                (l) => l.overtimeInCents,
                (l) => l.allowanceInCents,
                // La colonne affiche retenues + avance par ligne : le total
                // somme les mêmes montants.
                (l) => l.deductions.totalInCents + l.advanceInCents,
                (l) => l.netInCents,
              ])
                Text(
                  PayrollLabels.money(
                    sum(byCurrency[currency]!, amountOf),
                    currency,
                  ),
                  textAlign: TextAlign.end,
                  style: EteeloColumnTableRow.figures(
                    color: tone.headerInk,
                    strong: true,
                  ),
                ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
      ],
    );
  }
}
