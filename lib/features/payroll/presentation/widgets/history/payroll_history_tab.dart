import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mois tenus, du plus récent au plus ancien ; toucher un mois ouvre son
/// livre.
class PayrollHistoryTab extends StatelessWidget {
  final PayrollState state;

  const PayrollHistoryTab({super.key, required this.state});

  static const List<double?> _widths = [
    AppDimensions.payrollColMonth,
    AppDimensions.payrollColStatus,
    AppDimensions.payrollColCount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    AppDimensions.payrollColAmount,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final snapshot = state.snapshot;
    final views = state.history;
    final paid = PayrollLabels.perCurrency([
      for (final d in snapshot.disbursements)
        if (d.isLive) (d.amount.amountInCents, d.amount.currency),
    ]);
    final locked = snapshot.headers.values
        .where((h) => h.status == PayrollStatus.validated)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloKpiBand(
          cards: [
            EteeloKpiCardData(
              label: l10n.payrollHistoryMonths,
              value: snapshot.headers.length,
              accent: AppColors.bleuArdoise,
              accentSoft: AppColors.bleuArdoiseSoft,
              icon: Icons.calendar_month_outlined,
            ),
            EteeloKpiCardData(
              label: l10n.payrollHistoryPaid,
              valueLines: paid,
              accent: AppColors.presenceMarkPresentInk,
              accentSoft: AppColors.presenceMarkPresentSoft,
              icon: Icons.payments_outlined,
            ),
            EteeloKpiCardData(
              label: l10n.payrollHistoryLocked,
              value: locked,
              accent: AppColors.payrollValidated,
              accentSoft: AppColors.payrollValidatedSoft,
              icon: Icons.lock_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (snapshot.headers.isEmpty && views.every((v) => v.lines.isEmpty))
          EteeloEmptyResult(
            label: l10n.payrollHistoryEmpty,
            medallionIcon: Icons.history,
          )
        else
          StaffTable(
            minWidth: AppDimensions.payrollHistoryMinWidth,
            widths: _widths,
            endAligned: const {2, 3, 4, 5},
            headers: [
              l10n.payrollHistoryColMonth,
              l10n.payrollHistoryColStatus,
              l10n.payrollHistoryColAgents,
              l10n.payrollHistoryColGross,
              l10n.payrollHistoryColAdvances,
              l10n.payrollHistoryColNet,
              l10n.payrollHistoryColValidated,
            ],
            rowCount: views.length,
            row: (context, index) => _row(context, views[index], cubit),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, PayrollMonthView view, PayrollCubit cubit) {
    final l10n = AppLocalizations.of(context)!;
    final current = view.month == state.currentMonth;
    String sum(int Function(PayrollTotal total) of) =>
        PayrollLabels.perCurrency(
          view.totals.map((t) => (of(t), t.currency)),
        ).join('\n');
    final remaining = PayrollLabels.perCurrency([
      for (final line in view.payable)
        if (!view.disbursements.containsKey(line.staffMemberId))
          (line.netInCents, line.currency),
    ]);
    final header = view.header;
    final figures = StaffTableRow.figures();
    return StaffTableRow(
      widths: _widths,
      background: current ? AppColors.terreCuiteSoft : null,
      onTap: () => cubit.openMonth(view.month),
      cells: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PayrollLabels.month(context, view.month),
              style: AppTypography.labelLarge,
            ),
            if (current)
              Text(
                l10n.payrollHistoryCurrent,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.terreCuiteDark,
                ),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: PayrollStatusPill(phase: view.phase),
        ),
        Text('${view.lines.length}', textAlign: TextAlign.end, style: figures),
        Text(
          sum((t) => t.grossInCents),
          textAlign: TextAlign.end,
          style: figures,
        ),
        Text(
          sum((t) => t.advanceInCents),
          textAlign: TextAlign.end,
          style: figures,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              sum((t) => t.netInCents),
              textAlign: TextAlign.end,
              style: StaffTableRow.figures(strong: true),
            ),
            if (view.phase == PayrollPhase.validated && view.remainingCount > 0)
              Text(
                l10n.payrollHistoryRemaining(remaining.join(' · ')),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.presenceMarkLateInk,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Text(
            header?.validatedAt == null
                ? '—'
                : l10n.payrollHistoryValidatedBy(
                    PayrollLabels.day(context, header!.validatedAt!),
                    header.validatedBy ?? '—',
                  ),
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
