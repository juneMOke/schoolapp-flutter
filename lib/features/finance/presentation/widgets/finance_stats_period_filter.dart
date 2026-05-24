import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsPeriodFilter extends StatelessWidget {
  const FinanceStatsPeriodFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FinanceStatsBloc, FinanceStatsState>(
      buildWhen: (prev, curr) => prev.selectedPeriod != curr.selectedPeriod,
      builder: (context, state) {
        final selectedPeriodLabel = switch (state.selectedPeriod) {
          FinanceStatsPeriod.week => l10n.financeStatsPeriodWeekCurrent,
          FinanceStatsPeriod.month => l10n.financeStatsPeriodMonthCurrent,
          FinanceStatsPeriod.year => l10n.financeStatsPeriodYearCurrent,
        };

        return Semantics(
          container: true,
          label: l10n.financeStatsPeriodFilterA11yLabel(selectedPeriodLabel),
          child: SegmentedTabFilter<FinanceStatsPeriod>(
            options: [
              SegmentedTabOption(
                label: l10n.financeStatsPeriodWeekCurrent,
                value: FinanceStatsPeriod.week,
              ),
              SegmentedTabOption(
                label: l10n.financeStatsPeriodMonthCurrent,
                value: FinanceStatsPeriod.month,
              ),
              SegmentedTabOption(
                label: l10n.financeStatsPeriodYearCurrent,
                value: FinanceStatsPeriod.year,
              ),
            ],
            selected: state.selectedPeriod,
            onSelected: (period) {
              context.read<FinanceStatsBloc>().add(FinanceStatsRequested(period: period));
            },
          ),
        );
      },
    );
  }
}
