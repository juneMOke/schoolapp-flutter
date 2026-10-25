import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/dashboard/dashboard_period_tabs.dart';
import 'package:school_app_flutter/core/components/dashboard/dashboard_range_fields.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_dashboard_content.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord sous la barre : l'en-tête et la période, qui restent en
/// place sous un vide ou une erreur (c'est souvent la période qui en fait
/// sortir), puis les chiffres du serveur ou leur attente.
class HrPresenceDashboardBody extends StatelessWidget {
  final HrPresenceDashboardState state;

  /// Ouvre le Registre du jour, dans la coquille.
  final VoidCallback onOpenRegister;
  final ValueChanged<HrAttendanceStaffRow>? onOpen;

  const HrPresenceDashboardBody({
    super.key,
    required this.state,
    required this.onOpenRegister,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceDashboardCubit>();
    final dates = MaterialLocalizations.of(context);
    final year = context.select<AcademicYearContextBloc, String?>(
      (bloc) => bloc.state.context?.academicYear.name,
    );
    final yearStart = context.select<AcademicYearContextBloc, DateTime?>(
      (bloc) => bloc.state.context?.academicYear.startDate,
    );
    final window = state.window;
    final periodLabel = window == null
        ? ''
        : HrPresenceLabels.period(
            window,
            state.period,
            l10n,
            dates,
            schoolYear: year,
          );
    final canMark = PermissionGate.allowsAccess(
      context,
      kStaffAttendanceWriteAccess,
    );

    final header = HrPersonnelHeader(
      subtitle: window == null
          ? l10n.hrPresenceDashboardSubtitleBare
          : l10n.hrPresenceDashboardSubtitle(periodLabel),
      actions: [
        EteeloButton.ghost(
          label: l10n.hrPresenceRefresh,
          icon: Icons.refresh_rounded,
          onPressed: () => unawaited(cubit.reload()),
          fullWidth: false,
        ),
        if (canMark)
          EteeloButton.primary(
            label: l10n.hrPresenceActionMark,
            icon: Icons.how_to_reg_outlined,
            onPressed: onOpenRegister,
            fullWidth: false,
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        DashboardPeriodTabs(
          selected: state.period,
          onChanged: (period) => unawaited(cubit.setPeriod(period)),
        ),
        if (state.period == DashboardPeriod.custom && window != null) ...[
          const SizedBox(height: AppSpacing.md),
          DashboardRangeFields(
            window: window,
            yearStart: yearStart,
            onChanged: (range) => unawaited(cubit.setRange(range)),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _content(context, l10n, cubit, periodLabel, canMark),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    HrPresenceDashboardCubit cubit,
    String periodLabel,
    bool canMark,
  ) {
    final dashboard = state.dashboard;
    final window = state.window;
    switch (state.status) {
      case HrPresenceDashboardStatus.loading:
        return const HrPresenceDashboardSkeleton();
      case HrPresenceDashboardStatus.failure:
        return HrPresenceResultsErrorState(
          failure: state.failure,
          onRetry: () => unawaited(cubit.reload()),
        );
      case HrPresenceDashboardStatus.ready:
        if (dashboard == null || window == null) {
          return const HrPresenceDashboardSkeleton();
        }
        if (dashboard.classDays == 0) {
          return EteeloEmptyResult(
            label: l10n.hrPresenceNoClassDaysTitle,
            description: l10n.hrPresenceNoClassDaysMessage,
            medallionIcon: Icons.event_busy_outlined,
            fullWidthCard: true,
            primaryAction: state.period == DashboardPeriod.month
                ? null
                : EteeloButton.secondary(
                    label: l10n.dashboardPeriodMonth,
                    icon: Icons.calendar_month_outlined,
                    onPressed: () =>
                        unawaited(cubit.setPeriod(DashboardPeriod.month)),
                    fullWidth: false,
                  ),
          );
        }
        if (dashboard.staffCount == 0) {
          return EteeloEmptyResult(
            label: l10n.hrPresenceNoStaffTitle,
            description: l10n.hrPresenceNoStaffMessage,
            medallionIcon: Icons.groups_outlined,
            fullWidthCard: true,
          );
        }
        return HrPresenceDashboardContent(
          dashboard: dashboard,
          window: window,
          periodLabel: periodLabel,
          unsynced: state.unsynced,
          onCompleteMarking: canMark ? onOpenRegister : null,
          onOpen: onOpen,
        );
    }
  }
}
