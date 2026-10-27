import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/helpers/class_day_access.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_register_filters.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_lock.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_register.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_register_banners.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_month_placeholder.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_register_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_empty_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Registre du jour » d'une classe.
class ClassRegisterTab extends StatelessWidget {
  final ClassPresenceState state;
  final ClassDayRegister register;
  final String classroomName;

  const ClassRegisterTab({
    super.key,
    required this.state,
    required this.register,
    required this.classroomName,
  });

  @override
  Widget build(BuildContext context) => PermissionAware(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ClassPresenceCubit>();
    final day = register.day;
    final query = state.dayQuery;
    final lock = classDayLockIn(context, day, today: state.today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClassDayBanner(
          state: state,
          register: register,
          classroomName: classroomName,
        ),
        const SizedBox(height: AppSpacing.md),
        if (day.validated)
          ClassValidatedBanner(state: state, register: register),
        if (day.reopened && lock == ClassDayLock.needsAmend)
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.none,
            message: l10n.classPresenceReopenPastHint,
          ),
        if (day.monthClosed) ...[
          const SizedBox(height: AppSpacing.sm),
          PresenceWarning(
            icon: Icons.lock_outline,
            tone: PresenceStatus.none,
            message: l10n.classPresenceMonthClosedBanner,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (register.isEmpty)
          AttendanceResultsEmptyState(
            onOpenComposition: () => openClassComposition(context),
          )
        else ...[
          PresenceRegisterFilters(
            total: register.all.length,
            countOf: register.count,
            selected: query.status,
            onStatus: cubit.setDayStatus,
            viewMode: state.viewMode,
            showLegend: lock == null,
            toJustify: register.toJustify,
            toolbar: EteeloSearchToolbar(
              text: query.text,
              label: l10n.classPresenceSearchLabel,
              placeholder: l10n.classPresenceSearchPlaceholder,
              onTextChanged: cubit.setDayText,
              viewMode: state.viewMode,
              onViewModeChanged: cubit.setViewMode,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (register.isFilteredEmpty)
            PresenceFilterEmpty(
              label: l10n.classPresenceEmptyFilterTitle,
              allMarked: query.status == PresenceStatus.none,
              onShowAll: cubit.resetDayFilters,
            )
          else
            ClassRegisterView(
              register: register,
              viewMode: state.viewMode,
              classroomName: classroomName,
              canJustify:
                  classDayLockIn(
                    context,
                    day,
                    today: state.today,
                    justifying: true,
                  ) ==
                  null,
            ),
        ],
      ],
    );
  }
}
