import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_register_filters.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_grid.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_list.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_banners.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_empty.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Registre du jour ».
class StaffRegisterTab extends StatelessWidget {
  final StaffAttendanceState state;

  const StaffRegisterTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAttendanceCubit>();
    final register = state.register;
    final snapshot = state.snapshot;
    final lock = snapshot.dayLock(state.day);
    final monthClosed = snapshot.isMonthClosed(
      SchoolDayCalendar.monthOf(state.day),
    );
    final query = state.dayQuery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffDayBanner(state: state),
        const SizedBox(height: AppSpacing.md),
        if (lock != null && lock.locked)
          StaffValidatedBanner(
            state: state,
            lock: lock,
            canReopen: !monthClosed,
          )
        else if (lock != null && lock.syncState == RecordSyncState.failed)
          PresenceWarning(
            icon: Icons.sync_problem,
            tone: PresenceStatus.absent,
            message: l10n.staffAttendanceValidationRefused,
          ),
        if (monthClosed) ...[
          const SizedBox(height: AppSpacing.sm),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.none,
            message: l10n.staffAttendanceMonthClosedBanner,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (register.isEmpty)
          const StaffRegisterEmpty()
        else ...[
          PresenceRegisterFilters(
            total: register.all.length,
            countOf: register.count,
            selected: query.status,
            onStatus: cubit.setDayStatus,
            viewMode: state.viewMode,
            showLegend: PermissionGate.allows(
              context,
              kStaffAttendanceWriteAccess.requires,
            ),
            toJustify: register.toJustify,
            toolbar: StaffSearchToolbar(
              text: query.text,
              label: l10n.staffAttendanceSearchLabel,
              placeholder: l10n.staffAttendanceSearchPlaceholder,
              onTextChanged: cubit.setDayText,
              category: query.category,
              onCategoryChanged: cubit.setDayCategory,
              viewMode: state.viewMode,
              onViewModeChanged: cubit.setViewMode,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (register.isFilteredEmpty)
            PresenceFilterEmpty(
              label: l10n.staffAttendanceEmptyFilterTitle,
              allMarked: query.status == PresenceStatus.none,
              onShowAll: cubit.resetDayFilters,
            )
          else
            Opacity(
              opacity: register.frozen
                  ? AppDimensions.presenceMarkFrozenOpacity
                  : 1,
              child: state.viewMode == CollectionViewMode.grid
                  ? StaffAttendanceGrid(
                      register: register,
                      settings: snapshot.settings,
                    )
                  : StaffAttendanceList(register: register),
            ),
        ],
      ],
    );
  }
}
