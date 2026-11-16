import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/register_balance_chart.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/states/treasury_results_error_state.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_panel.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/cash_report_opener.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_date_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'évolution des caisses (A3) : les filtres de période, le bandeau qui dit
/// la plage, le nombre de jours de caisse et la granularité **retenue par le
/// serveur**, puis une courbe par caisse : côte à côte quand la largeur le
/// permet (poste), l'une sous l'autre sinon.
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
            TreasurySectionHeader(
              icon: Icons.trending_up,
              title: l10n.treasuryEvolutionTitle,
              subtitle: l10n.treasuryEvolutionSubtitle,
            ),
            SegmentedTabFilter<EvolutionPeriod>(
              style: TreasuryTones.filter,
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
          _Band(evolution: evolution, onPointHint: l10n.treasuryChartOpenHint),
          const SizedBox(height: AppSpacing.md + 2),
          EteeloGridView(
            itemCount: evolution.series.length,
            padding: EdgeInsets.zero,
            minItemWidth: AppDimensions.treasuryChartMinWidth,
            spacing: AppSpacing.md + 2,
            itemBuilder: (context, index) => RegisterBalanceChart(
              series: evolution.series[index],
              granularity: evolution.granularity,
              period: evolution.period,
              onOpenPoint: (point) =>
                  openPointReport(context, evolution.granularity, point),
            ),
          ),
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

  /// « Touchez un point pour ouvrir son rapport », quand un point s'ouvre.
  final String? onPointHint;

  const _Band({required this.evolution, this.onPointHint});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final granularity = RegisterBalanceChart.granularityLabel(
      l10n,
      evolution.granularity,
    );
    // La semaine se montre du lundi au samedi (R4), même si le serveur la
    // borne au dimanche ; « Aujourd'hui » n'est pas une plage.
    final to =
        evolution.period == EvolutionPeriod.week &&
            evolution.to.weekday == DateTime.sunday
        ? DateTime(evolution.to.year, evolution.to.month, evolution.to.day - 1)
        : evolution.to;
    final range = evolution.period == EvolutionPeriod.today
        ? '${l10n.treasuryPeriodToday}, ${l10n.treasuryDayShort(evolution.from)}'
        : l10n.treasuryRangeLabel(evolution.from, to);
    final rest = [
      l10n.treasuryCashDays(evolution.cashDays),
      l10n.treasuryDisplayAs(granularity),
      if (evolution.period == EvolutionPeriod.custom) l10n.treasuryAutoChosen,
    ];
    return TreasuryNoteBand(
      icon: Icons.date_range,
      text: TextSpan(
        children: [
          TextSpan(
            text: range,
            style: const TextStyle(
              color: AppColors.treasuryNoteStrong,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: ' · ${rest.join(' · ')}'),
        ],
      ),
      hint: onPointHint,
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
      final picked = await showTreasuryDatePicker(
        context,
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

/// Le rapport d'une tranche de courbe (R7) : la journée d'une heure ou d'un
/// jour, la semaine ISO (lundi → samedi) d'une semaine, le mois d'un mois.
Future<void> openPointReport(
  BuildContext context,
  EvolutionGranularity granularity,
  EvolutionPoint point,
) {
  final l10n = AppLocalizations.of(context)!;
  final start = SchoolTime.wallClock(point.start);
  final day = DateTime(start.year, start.month, start.day);
  final (id, from, to) = pointReport(granularity, day);
  final title = granularity == EvolutionGranularity.month
      ? l10n.treasuryMonthOf(from)
      : from == to
      ? l10n.treasuryReportDay(from)
      : l10n.treasuryRangeLabel(from, to);
  return openCashReport(
    context,
    id: id,
    title: title,
    format: CashReportFormat.pdf,
  );
}

/// L'id du rapport d'une tranche et sa plage : la journée d'une heure ou
/// d'un jour, la semaine ISO (lundi → samedi) d'une semaine même coupée au
/// bord du mois, le mois civil d'un mois.
(String, DateTime, DateTime) pointReport(
  EvolutionGranularity granularity,
  DateTime day,
) {
  switch (granularity) {
    case EvolutionGranularity.hour || EvolutionGranularity.day:
      return (CashReportIds.daily(day), day, day);
    case EvolutionGranularity.week:
      final monday = DateTime(day.year, day.month, day.day - day.weekday + 1);
      final saturday = DateTime(monday.year, monday.month, monday.day + 5);
      return (CashReportIds.weekly(monday, saturday), monday, saturday);
    case EvolutionGranularity.month:
      final first = DateTime(day.year, day.month);
      final last = DateTime(day.year, day.month + 1, 0);
      return (CashReportIds.monthly(first, last), first, last);
  }
}
