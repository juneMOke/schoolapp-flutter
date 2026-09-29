import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

export 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_buttons.dart';

// Les contrôles d'une ligne du registre, partagés par la carte de la grille et
// la ligne de la liste : une heure, le compteur d'heures, le bouton de
// justification, la reprise d'un envoi refusé.

/// Le détail d'un statut : « +22 min après 07:30 », « Absence justifiée »…
String staffStatusDetail(
  AppLocalizations l10n,
  StaffDayRow row,
  StaffAttendanceSettings settings,
) {
  final record = row.record;
  return switch (row.status) {
    StaffAttendanceStatus.none => l10n.staffAttendanceNotMarked,
    StaffAttendanceStatus.present => l10n.staffAttendanceOnTime,
    StaffAttendanceStatus.late => l10n.staffAttendanceLateDetail(
      record!.lateMinutes,
      settings.start.wire,
    ),
    StaffAttendanceStatus.absent =>
      record!.isJustified
          ? l10n.staffAttendanceAbsenceJustified
          : l10n.staffAttendanceAbsenceUnjustified,
  };
}

/// Une heure (arrivée, départ) : en chiffres quand elle est posée, en pointillé
/// sinon. Toucher ouvre la saisie.
class StaffTimeButton extends StatelessWidget {
  final String label;
  final StaffClockTime? time;
  final VoidCallback onTap;

  const StaffTimeButton({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = this.time;
    return Semantics(
      button: true,
      label: '$label ${time?.wire ?? ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.staffAttendanceIconButtonSize,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: time == null ? AppColors.borderStrong : AppColors.border,
            ),
            color: time == null ? null : AppColors.surface,
          ),
          alignment: Alignment.center,
          child: Text(
            time?.wire ?? label,
            style: time == null
                ? AppTypography.labelMedium.copyWith(
                    color: AppColors.textMutedAa,
                  )
                : AppTypography.money.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Les heures prestées d'un vacataire à l'heure : − 3 h +, de 0 à 10 h.
class StaffHoursStepper extends StatelessWidget {
  final int? minutes;
  final ValueChanged<int> onStep;

  const StaffHoursStepper({
    super.key,
    required this.minutes,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = minutes ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          tooltip: l10n.staffAttendanceHoursLess,
          onTap: value <= 0 ? null : () => onStep(-1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            StaffAttendanceLabels.hours(l10n, value),
            style: AppTypography.labelLarge,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          tooltip: l10n.staffAttendanceHoursMore,
          onTap: value >= StaffAttendanceRecord.maxWorkedMinutes
              ? null
              : () => onStep(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) =>
      StaffSquareIconButton(icon: icon, tooltip: tooltip, onPressed: onTap);
}

/// « Justifier », ou le motif posé, en vert.
class StaffJustifyButton extends StatelessWidget {
  final StaffAttendanceRecord record;
  final VoidCallback onTap;

  const StaffJustifyButton({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final justification = record.justification;
    final tone = StaffAttendanceTone.of(
      justification == null ? record.status : StaffAttendanceStatus.present,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brPill,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.staffAttendanceIconButtonSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: tone.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              justification == null ? Icons.edit_note : Icons.task_alt,
              size: AppSpacing.lg,
              color: tone.ink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                justification == null
                    ? l10n.staffAttendanceJustify
                    : StaffAttendanceLabels.reason(l10n, justification.reason),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(color: tone.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
