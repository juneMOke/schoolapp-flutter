import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_agent_heading.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_actions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte d'un agent dans la grille du registre. **Toute** la carte fait
/// avancer le cycle (présent › en retard › absent) ; les boutons du pied ont
/// leur propre geste et ne font pas avancer le cycle.
class StaffAttendanceCard extends StatelessWidget {
  final StaffDayRow row;
  final StaffAttendanceSettings settings;
  final bool frozen;

  const StaffAttendanceCard({
    super.key,
    required this.row,
    required this.settings,
    required this.frozen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(row.status);
    final actions = StaffRowActions(context, row, frozen: frozen);
    final unmarked = row.status == StaffAttendanceStatus.none;
    return Material(
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(
          color: unmarked ? tone.border : tone.color,
          width: AppDimensions.staffAttendanceBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: actions.cycle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [tone.soft, AppColors.surfaceRaised],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaffAgentHeading(row: row),
                const SizedBox(height: AppSpacing.md),
                _StatusBlock(row: row, settings: settings),
                const SizedBox(height: AppSpacing.md),
                _Footer(row: row, actions: actions, l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBlock extends StatelessWidget {
  final StaffDayRow row;
  final StaffAttendanceSettings settings;

  const _StatusBlock({required this.row, required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(row.status);
    return Row(
      children: [
        AnimatedContainer(
          // Le médaillon change de teinte au pointage ; mouvement réduit
          // respecté.
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.pop,
          curve: AppMotion.outCurve,
          width: AppDimensions.staffAttendanceMedallionSize,
          height: AppDimensions.staffAttendanceMedallionSize,
          decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
          child: Icon(
            tone.icon,
            color: AppColors.textOnDark,
            size: AppDimensions.staffAttendanceMedallionIconSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StaffAttendanceLabels.status(l10n, row.status),
                style: AppTypography.titleMedium.copyWith(color: tone.ink),
              ),
              Text(
                staffStatusDetail(l10n, row, settings),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final StaffDayRow row;
  final StaffRowActions actions;
  final AppLocalizations l10n;

  const _Footer({required this.row, required this.actions, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final record = row.record;
    final status = row.status;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (status.hasArrival) ...[
          StaffTimeButton(
            label: l10n.staffAttendanceArrival,
            time: record?.arrival,
            onTap: actions.editArrival,
          ),
          StaffTimeButton(
            label: l10n.staffAttendanceDeparture,
            time: record?.departure,
            onTap: actions.editDeparture,
          ),
          if (row.isHourly)
            StaffHoursStepper(
              minutes: record?.workedMinutes,
              onStep: actions.adjustHours,
            ),
        ],
        if (record != null && status.isIncident)
          StaffJustifyButton(record: record, onTap: actions.justify),
        if (record != null)
          StaffRetryButton(record: record, onRetry: actions.retry),
        if (status.isMarked)
          StaffSquareIconButton(
            icon: Icons.rotate_left,
            tooltip: l10n.staffAttendanceClearTooltip,
            onPressed: actions.clear,
          ),
      ],
    );
  }
}
