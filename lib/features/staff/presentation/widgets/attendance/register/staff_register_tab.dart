import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_warning.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_grid.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_list.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_day_banner.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_day_filters.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_actions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_empty.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_validated_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Registre du jour ».
class StaffRegisterTab extends StatelessWidget {
  final StaffAttendanceState state;

  const StaffRegisterTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAttendanceCubit>();
    final actions = StaffRegisterActions(context);
    final register = state.register;
    final snapshot = state.snapshot;
    final lock = snapshot.dayLock(state.day);
    final monthClosed = snapshot.isMonthClosed(
      StaffWorkCalendar.monthOf(state.day),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffDayBanner(
          register: register,
          settings: snapshot.settings,
          isToday: state.isToday,
          onPrevious: () => unawaited(cubit.stepDay(-1)),
          onNext: state.isToday ? null : () => unawaited(cubit.stepDay(1)),
          onToday: () => unawaited(cubit.goToday()),
          onSettings: () => unawaited(actions.openSettings()),
          onMarkRemaining: actions.markRemaining,
          onValidate: () => unawaited(actions.validate(register)),
        ),
        const SizedBox(height: AppSpacing.md),
        if (lock != null && lock.locked)
          StaffValidatedBanner(
            lock: lock,
            register: register,
            onReopen: monthClosed ? null : actions.reopen,
          )
        else if (lock != null && lock.syncState == StaffSyncState.failed)
          StaffAttendanceWarning(
            icon: Icons.sync_problem,
            tone: StaffAttendanceStatus.absent,
            message: l10n.staffAttendanceValidationRefused,
          ),
        if (monthClosed) ...[
          const SizedBox(height: AppSpacing.sm),
          StaffAttendanceWarning(
            icon: Icons.lock_outline,
            tone: StaffAttendanceStatus.none,
            message: l10n.staffAttendanceMonthClosedBanner,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (register.isEmpty)
          const StaffRegisterEmpty(filtered: false)
        else ...[
          StaffDayFilters(
            register: register,
            query: state.dayQuery,
            viewMode: state.viewMode,
            onStatus: cubit.setDayStatus,
            onCategory: cubit.setDayCategory,
            onText: cubit.setDayText,
            onViewMode: cubit.setViewMode,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (register.isFilteredEmpty)
            StaffRegisterEmpty(
              filtered: true,
              status: state.dayQuery.status,
              onShowAll: cubit.resetDayFilters,
            )
          else
            Opacity(
              opacity: register.frozen
                  ? AppDimensions.staffAttendanceFrozenOpacity
                  : 1,
              child: state.viewMode == StaffViewMode.grid
                  ? StaffAttendanceGrid(
                      register: register,
                      settings: snapshot.settings,
                    )
                  : StaffAttendanceList(
                      register: register,
                      settings: snapshot.settings,
                    ),
            ),
        ],
      ],
    );
  }
}
