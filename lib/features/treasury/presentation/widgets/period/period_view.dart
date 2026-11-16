import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_step_gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_period_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_day_tile.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_totals_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/closing_report_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Clôture de caisse, vues hebdomadaire et mensuelle (B7) : la navigation de
/// période, une carte de totaux par caisse, puis « Jour par jour ».
class PeriodView extends StatelessWidget {
  /// La journée touchée : l'écran repasse en Journalier sur elle.
  final ValueChanged<DateTime> onOpenDay;

  /// « Aujourd'hui » selon le serveur, pour le badge de la ligne du jour.
  final DateTime today;

  /// Les filtres Journalier · Hebdomadaire · Mensuel, dans la même carte.
  final Widget? filters;

  /// La journée ouverte à côté (écran large), marquée dans la liste.
  final DateTime? selectedDay;

  const PeriodView({
    super.key,
    required this.onOpenDay,
    required this.today,
    this.filters,
    this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<CashPeriodCubit, CashPeriodState>(
      builder: (context, state) {
        final cubit = context.read<CashPeriodCubit>();
        final week = state.scope == ClosingScope.week;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayNavBar(
              date: state.from,
              isToday: cubit.isCurrent,
              label: week
                  ? l10n.treasuryWeekOf(state.from, state.to)
                  : l10n.treasuryMonthOf(state.from),
              currentHint: l10n.treasuryInProgress,
              goCurrentLabel: week
                  ? l10n.treasuryCurrentWeek
                  : l10n.treasuryCurrentMonth,
              periodTooltips: true,
              onPrevious: cubit.nextFrom(-1) == null
                  ? null
                  : () => cubit.step(-1),
              onNext: cubit.nextFrom(1) == null ? null : () => cubit.step(1),
              onToday: cubit.goCurrent,
              filters: filters,
            ),
            const SizedBox(height: AppSpacing.lg),
            switch (state.status) {
              CashPeriodStatus.loading => EteeloListSkeleton(
                rowCount: 3,
                pillCount: 2,
                showAvatar: false,
                semanticsLabel: l10n.treasuryPeriodLoading,
              ),
              CashPeriodStatus.failure => TreasuryResultsErrorState(
                failure: state.failure ?? const ServerFailure(),
                onRetry: cubit.load,
              ),
              CashPeriodStatus.ready => TreasuryStepGestures(
                onPrevious: cubit.nextFrom(-1) == null
                    ? null
                    : () => cubit.step(-1),
                onNext: cubit.nextFrom(1) == null ? null : () => cubit.step(1),
                child: _content(context, state, state.period!),
              ),
            },
          ],
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    CashPeriodState state,
    TreasuryPeriod period,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final registers = [for (final t in period.registers) t.register];
    // La plage DEMANDÉE : le serveur ramène `from` à la mise en service de la
    // première caisse, ce qui ne change ni la semaine ni le mois du rapport.
    final week = state.scope == ClosingScope.week;
    final (from, to) = (state.from, state.to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClosingReportBar(
          label: week
              ? l10n.treasuryReportOneWeekly
              : l10n.treasuryReportOneMonthly,
          title: capitalizeFirst(
            week ? l10n.treasuryWeekOf(from, to) : l10n.treasuryMonthOf(from),
          ),
          reportId: week
              ? CashReportIds.weekly(from, to)
              : CashReportIds.monthly(from, to),
        ),
        const SizedBox(height: AppSpacing.lg),
        EteeloGridView(
          itemCount: period.registers.length,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasuryDayCardMinWidth,
          spacing: AppSpacing.lg,
          itemBuilder: (context, index) =>
              PeriodTotalsCard(totals: period.registers[index]),
        ),
        const SizedBox(height: AppSpacing.xl),
        TreasurySectionHeader(
          icon: Icons.list,
          title: l10n.treasuryDayByDay,
          subtitle: l10n.treasuryDayByDayHint,
        ),
        if (period.days.isEmpty)
          Text(
            l10n.treasuryPeriodEmpty,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          EteeloColumnTable(
            raised: true,
            tone: TreasuryTones.table,
            cardsBelow: AppBreakpoints.dataTableCardsMax,
            minWidth: PeriodDayColumns.minWidth(registers.length),
            widths: PeriodDayColumns.widths(registers.length),
            headers: [
              l10n.treasuryDayColumn,
              for (final r in registers) l10n.treasuryDayRegisterColumn(r.name),
              l10n.treasuryClosureColumn,
            ],
            endAligned: {registers.length + 1},
            rowCount: period.days.length,
            row: (context, index) {
              final row = period.days[index];
              return periodDayRow(
                context,
                row: row,
                registers: registers,
                isToday: row.day == today,
                selected: row.day == selectedDay,
                onOpen: () => onOpenDay(row.day),
              );
            },
          ),
      ],
    );
  }
}
