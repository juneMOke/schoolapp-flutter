import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_agent_month.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_stats.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_card_frame.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_count_tile.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_agent_picker.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_holiday_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_incident_list.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_month_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_month_nav.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_empty.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Fiche mensuelle » : un agent, un mois, en lecture seule.
class StaffAgentMonthTab extends StatelessWidget {
  final StaffAttendanceState state;

  const StaffAgentMonthTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StaffAttendanceCubit>();
    final members = state.snapshot.members;
    if (members.isEmpty) {
      return const StaffRegisterEmpty(filtered: false);
    }
    final member = members.firstWhere(
      (m) => m.id == state.agentId,
      orElse: () => members.first,
    );
    final month = StaffAgentMonth.build(
      state.snapshot,
      member: member,
      month: state.month,
      today: state.today,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            StaffAgentPicker(
              members: members,
              selected: member,
              onSelected: (picked) => cubit.openAgent(picked.id),
            ),
            StaffMonthNav(
              month: state.month,
              isCurrent: state.month == state.today.substring(0, 7),
              onPrevious: () => unawaited(cubit.stepMonth(-1)),
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (month.isHoliday)
          StaffHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          )
        else ...[
          _Kpis(stats: month.stats),
          const SizedBox(height: AppSpacing.lg),
          StaffAttendanceCardFrame(
            title: StaffAttendanceLabels.callName(member),
            child: StaffMonthCalendar(days: month.calendar),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaffAttendanceCardFrame(
            title: AppLocalizations.of(context)!.staffAttendanceIncidentsTitle,
            child: StaffIncidentList(incidents: month.incidents),
          ),
        ],
      ],
    );
  }
}

class _Kpis extends StatelessWidget {
  final StaffMonthStats stats;

  const _Kpis({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = stats.amount;
    final tiles = [
      StaffCountTile(
        tone: StaffAttendanceStatus.present,
        label: stats.isHourly
            ? l10n.staffAttendanceKpiDaysWorked
            : l10n.staffAttendanceKpiPresences,
        value: stats.isHourly
            ? '${stats.present}'
            : l10n.staffAttendanceKpiRatio(stats.present, stats.workDays),
      ),
      StaffCountTile(
        tone: StaffAttendanceStatus.late,
        label: l10n.staffAttendanceKpiLates,
        value: '${stats.late}',
        detail: l10n.staffAttendanceKpiLatesDetail(
          stats.lateMinutes,
          stats.lateUnjustified,
        ),
      ),
      StaffCountTile(
        tone: StaffAttendanceStatus.absent,
        label: l10n.staffAttendanceKpiAbsences,
        value: '${stats.absent}',
        detail: l10n.staffAttendanceKpiAbsencesDetail(
          stats.absentJustified,
          stats.absentUnjustified,
        ),
      ),
      if (stats.isHourly)
        StaffCountTile(
          tone: StaffAttendanceStatus.none,
          label: l10n.staffAttendanceKpiHours,
          value: StaffAttendanceLabels.hours(stats.workedMinutes),
          detail: amount == null ? null : MoneyFormat.format(amount),
        )
      else
        StaffCountTile(
          tone: StaffAttendanceStatus.none,
          label: l10n.staffAttendanceKpiNotMarked,
          value: '${stats.notMarked}',
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >
                AppDimensions.staffAttendanceKpiWideBreakpoint
            ? 4
            : 2;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}
