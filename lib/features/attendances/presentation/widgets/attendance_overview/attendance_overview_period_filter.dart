import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sélecteur de période (Année / Mois / Semaine) du tableau de bord.
///
/// Ne dispatche QUE la période (ancres null) — comme les dashboards Finance et
/// Inscription ; le backend retombe sur la période courante.
class AttendanceOverviewPeriodFilter extends StatelessWidget {
  const AttendanceOverviewPeriodFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AttendanceOverviewBloc, AttendanceOverviewState>(
      buildWhen: (prev, curr) => prev.selectedPeriod != curr.selectedPeriod,
      builder: (context, state) {
        return Semantics(
          container: true,
          label: l10n.presencePeriodFilterA11yLabel,
          child: SegmentedTabFilter<StatsPeriod>(
            options: [
              SegmentedTabOption(
                label: l10n.presencePeriodYear,
                value: StatsPeriod.year,
              ),
              SegmentedTabOption(
                label: l10n.presencePeriodMonth,
                value: StatsPeriod.month,
              ),
              SegmentedTabOption(
                label: l10n.presencePeriodWeek,
                value: StatsPeriod.week,
              ),
            ],
            selected: state.selectedPeriod,
            onSelected: (period) => context.read<AttendanceOverviewBloc>().add(
              AttendanceOverviewRequested(period: period),
            ),
          ),
        );
      },
    );
  }
}
