import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/register_balance_chart.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'évolution des caisses (A3) : les filtres de période, le bandeau qui dit
/// la plage, le nombre de jours de caisse et la granularité **retenue par le
/// serveur**, puis une courbe par caisse, l'une sous l'autre.
class EvolutionPanel extends StatelessWidget {
  /// Bornes du sélecteur de la période libre (R15).
  final DateTime firstDay;
  final DateTime today;

  const EvolutionPanel({
    super.key,
    required this.firstDay,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TreasuryEvolutionCubit, TreasuryEvolutionState>(
      builder: (context, state) {
        final cubit = context.read<TreasuryEvolutionCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: AppColors.terreCuite),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.treasuryEvolutionTitle,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        l10n.treasuryEvolutionSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedTabFilter<EvolutionPeriod>(
              semanticsLabel: l10n.treasuryEvolutionTitle,
              selected: state.period,
              onSelected: cubit.periodChanged,
              wrap: true,
              options: [
                SegmentedTabOption(
                  label: l10n.treasuryPeriodToday,
                  value: EvolutionPeriod.today,
                  icon: Icons.schedule,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryPeriodWeek,
                  value: EvolutionPeriod.week,
                  icon: Icons.calendar_today_outlined,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryPeriodMonth,
                  value: EvolutionPeriod.month,
                  icon: Icons.date_range,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryPeriodYear,
                  value: EvolutionPeriod.year,
                  icon: Icons.event_available,
                ),
                SegmentedTabOption(
                  label: l10n.treasuryPeriodCustom,
                  value: EvolutionPeriod.custom,
                  icon: Icons.filter_alt_outlined,
                ),
              ],
            ),
            if (state.period == EvolutionPeriod.custom) ...[
              const SizedBox(height: AppSpacing.md),
              _CustomRange(state: state, firstDay: firstDay, today: today),
            ],
            const SizedBox(height: AppSpacing.md),
            _body(context, state),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, TreasuryEvolutionState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.rangeError) {
      return Text(
        l10n.treasuryRangeChooseValid,
        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
      );
    }
    final evolution = state.evolution;
    return switch (state.status) {
      TreasuryEvolutionStatus.loading => EteeloListSkeleton(
        rowCount: 2,
        pillCount: 3,
        showAvatar: false,
        semanticsLabel: l10n.treasuryEvolutionLoading,
      ),
      TreasuryEvolutionStatus.failure => TreasuryResultsErrorState(
        failure: state.failure ?? const ServerFailure(),
        onRetry: context.read<TreasuryEvolutionCubit>().load,
      ),
      TreasuryEvolutionStatus.ready when evolution != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Band(evolution: evolution),
          for (final series in evolution.series) ...[
            const SizedBox(height: AppSpacing.md),
            RegisterBalanceChart(
              series: series,
              granularity: evolution.granularity,
              period: evolution.period,
            ),
          ],
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// « 1 oct. → 22 oct. 2026 · 19 jours de caisse · affichage semaine par
/// semaine », et pour une période libre « (choisi automatiquement selon la
/// durée) ».
class _Band extends StatelessWidget {
  final TreasuryEvolution evolution;

  const _Band({required this.evolution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final granularity = RegisterBalanceChart.granularityLabel(
      l10n,
      evolution.granularity,
    );
    final parts = [
      l10n.treasuryRangeLabel(evolution.from, evolution.to),
      l10n.treasuryCashDays(evolution.cashDays),
      l10n.treasuryDisplayAs(granularity),
      if (evolution.period == EvolutionPeriod.custom) l10n.treasuryAutoChosen,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.terreCuite.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range,
            size: AppSpacing.lg,
            color: AppColors.terreCuite,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(parts.join(' · '), style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Du / Au de la période libre (30 derniers jours par défaut), bornés au
/// début de l'historique et à aujourd'hui. Fin avant début : bordure rouge et
/// message, aucun appel.
class _CustomRange extends StatelessWidget {
  final TreasuryEvolutionState state;
  final DateTime firstDay;
  final DateTime today;

  const _CustomRange({
    required this.state,
    required this.firstDay,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TreasuryEvolutionCubit>();
    final localizations = MaterialLocalizations.of(context);
    Future<void> pick(bool isFrom) async {
      final initial = isFrom ? state.customFrom : state.customTo;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(firstDay) ? firstDay : initial,
        firstDate: firstDay,
        lastDate: today,
      );
      if (picked == null || !context.mounted) return;
      await cubit.customRangeChanged(
        isFrom ? picked : state.customFrom,
        isFrom ? state.customTo : picked,
      );
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EteeloButton.secondary(
          label:
              '${l10n.treasuryRangeFrom} '
              '${localizations.formatMediumDate(state.customFrom)}',
          icon: Icons.calendar_today_outlined,
          onPressed: () => pick(true),
          fullWidth: false,
        ),
        EteeloButton.secondary(
          label:
              '${l10n.treasuryRangeTo} '
              '${localizations.formatMediumDate(state.customTo)}',
          icon: Icons.calendar_today_outlined,
          onPressed: () => pick(false),
          fullWidth: false,
        ),
        if (state.rangeError)
          Text(
            l10n.treasuryRangeInvalid,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
      ],
    );
  }
}
