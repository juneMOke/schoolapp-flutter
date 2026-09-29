import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un statut de pointage en pastille : icône et libellé dans sa teinte.
class StaffAttendanceStatusPill extends StatelessWidget {
  final StaffAttendanceStatus status;

  const StaffAttendanceStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = StaffAttendanceTone.of(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tone.icon, size: AppSpacing.lg, color: tone.ink),
          const SizedBox(width: AppSpacing.xs),
          Text(
            StaffAttendanceLabels.status(AppLocalizations.of(context)!, status),
            style: AppTypography.labelMedium.copyWith(color: tone.ink),
          ),
        ],
      ),
    );
  }
}
