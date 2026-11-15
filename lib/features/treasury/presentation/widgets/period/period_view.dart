import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_period_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/closing/day_nav_bar.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_day_tile.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/period/period_totals_card.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Clôture de caisse, vues hebdomadaire et mensuelle (B7) : la navigation de
/// période, une carte de totaux par caisse, puis « Jour par jour ».
class PeriodView extends StatelessWidget {
  /// La journée touchée : l'écran repasse en Journalier sur elle.
  final ValueChanged<DateTime> onOpenDay;

  /// « Aujourd'hui » selon le serveur, pour le badge de la ligne du jour.
  final DateTime today;

  const PeriodView({super.key, required this.onOpenDay, required this.today});

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
              CashPeriodStatus.ready => _content(context, state.period!),
            },
          ],
        );
      },
    );
  }

  Widget _content(BuildContext context, TreasuryPeriod period) {
    final l10n = AppLocalizations.of(context)!;
    final registers = [for (final t in period.registers) t.register];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloGridView(
          itemCount: period.registers.length,
          padding: EdgeInsets.zero,
          minItemWidth: AppDimensions.treasuryDayCardMinWidth,
          spacing: AppSpacing.lg,
          itemBuilder: (context, index) =>
              PeriodTotalsCard(totals: period.registers[index]),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.treasuryDayByDay, style: AppTypography.titleMedium),
        Text(
          l10n.treasuryDayByDayHint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (period.days.isEmpty)
          Text(
            l10n.treasuryPeriodEmpty,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.brMd,
              child: Column(
                children: [
                  for (final (index, row) in period.days.indexed) ...[
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.border),
                    PeriodDayTile(
                      row: row,
                      registers: registers,
                      isToday: row.day == today,
                      onOpen: () => onOpenDay(row.day),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
