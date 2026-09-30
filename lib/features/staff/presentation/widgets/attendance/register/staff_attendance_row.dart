import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_agent_heading.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_actions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_controls.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_status_segment.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes d'une ligne du registre, partagées par l'en-tête et les
/// lignes pour qu'elles s'alignent au pixel.
class StaffAttendanceRowLayout extends StatelessWidget {
  final Widget agent;
  final Widget status;
  final Widget times;
  final Widget? hours;
  final Widget late;
  final Widget action;

  const StaffAttendanceRowLayout({
    super.key,
    required this.agent,
    required this.status,
    required this.times,
    required this.late,
    required this.action,
    this.hours,
  });

  @override
  Widget build(BuildContext context) {
    final hours = this.hours;
    return Row(
      children: [
        Expanded(flex: 6, child: agent),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: AppDimensions.staffAttendanceColStatus, child: status),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: AppDimensions.staffAttendanceColTimes, child: times),
        if (hours != null) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: AppDimensions.staffAttendanceColHours, child: hours),
        ],
        const SizedBox(width: AppSpacing.sm),
        Expanded(flex: 5, child: late),
        SizedBox(width: AppDimensions.staffAttendanceColAction, child: action),
      ],
    );
  }
}

/// Une ligne du registre : filet gauche et voile dans la teinte du statut.
class StaffAttendanceRow extends StatelessWidget {
  final StaffDayRow row;
  final StaffAttendanceSettings settings;
  final bool frozen;
  final bool showHours;

  const StaffAttendanceRow({
    super.key,
    required this.row,
    required this.settings,
    required this.frozen,
    required this.showHours,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(row.status);
    final actions = StaffRowActions(context, row, frozen: frozen);
    final record = row.record;
    final status = row.status;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brMd,
        border: Border(
          left: BorderSide(
            color: tone.color,
            width: AppDimensions.staffAttendanceAccentWidth,
          ),
        ),
        gradient: LinearGradient(
          colors: [tone.soft, AppColors.surfaceRaised],
          stops: const [0, AppDimensions.staffAttendanceRowTintStop],
        ),
      ),
      child: StaffAttendanceRowLayout(
        agent: StaffAgentHeading(row: row),
        status: StaffStatusSegment(status: status, onChoose: actions.choose),
        times: status.hasArrival
            ? Row(
                children: [
                  Expanded(
                    child: StaffTimeButton(
                      label: l10n.staffAttendanceArrival,
                      time: record?.arrival,
                      onTap: actions.editArrival,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: StaffTimeButton(
                      label: l10n.staffAttendanceDeparture,
                      time: record?.departure,
                      onTap: actions.editDeparture,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
        hours: !showHours
            ? null
            : row.isHourly && status.hasArrival
            ? StaffHoursStepper(
                minutes: record?.workedMinutes,
                onStep: actions.adjustHours,
              )
            : const SizedBox.shrink(),
        late: _LateCell(row: row, onJustify: actions.justify),
        action: record == null
            ? const SizedBox.shrink()
            : StaffRetryButton(record: record, onRetry: actions.retry),
      ),
    );
  }
}

class _LateCell extends StatelessWidget {
  final StaffDayRow row;
  final VoidCallback onJustify;

  const _LateCell({required this.row, required this.onJustify});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final record = row.record;
    final tone = StaffAttendanceTone.of(row.status);
    final text = switch (row.status) {
      StaffAttendanceStatus.none => l10n.staffAttendanceNotMarked,
      StaffAttendanceStatus.present => l10n.staffAttendanceOnTimeShort,
      StaffAttendanceStatus.late =>
        '+${l10n.staffAttendanceMinutes(record!.lateMinutes)}',
      StaffAttendanceStatus.absent => null,
    };
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (text != null)
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(color: tone.ink),
          ),
        if (record != null && row.status.isIncident)
          StaffJustifyButton(record: record, onTap: onJustify),
      ],
    );
  }
}
