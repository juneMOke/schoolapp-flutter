import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Filtre de période adapté à [EnrollmentStatsPeriod] + dispatch BLoC.
class EnrollmentStatsPeriodFilter extends StatelessWidget {
  const EnrollmentStatsPeriodFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<EnrollmentStatsBloc, EnrollmentStatsState>(
      buildWhen: (prev, curr) => prev.selectedPeriod != curr.selectedPeriod,
      builder: (context, state) {
        final selectedPeriodLabel = switch (state.selectedPeriod) {
          EnrollmentStatsPeriod.week => l10n.enrollmentStatsPeriodWeekCurrent,
          EnrollmentStatsPeriod.month => l10n.enrollmentStatsPeriodMonthCurrent,
          EnrollmentStatsPeriod.year => l10n.enrollmentStatsPeriodYearCurrent,
        };

        return Semantics(
          container: true,
          label: l10n.enrollmentStatsPeriodFilterA11yLabel(selectedPeriodLabel),
          child: SegmentedTabFilter<EnrollmentStatsPeriod>(
            options: [
              SegmentedTabOption(
                label: l10n.enrollmentStatsPeriodWeekCurrent,
                value: EnrollmentStatsPeriod.week,
              ),
              SegmentedTabOption(
                label: l10n.enrollmentStatsPeriodMonthCurrent,
                value: EnrollmentStatsPeriod.month,
              ),
              SegmentedTabOption(
                label: l10n.enrollmentStatsPeriodYearCurrent,
                value: EnrollmentStatsPeriod.year,
              ),
            ],
            selected: state.selectedPeriod,
            onSelected: (period) =>
                context.read<EnrollmentStatsBloc>().add(
                      EnrollmentStatsRequested(period: period),
                    ),
          ),
        );
      },
    );
  }
}
