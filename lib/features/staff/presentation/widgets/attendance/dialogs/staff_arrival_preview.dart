import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_rules.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'encart qui dit, avant d'enregistrer, comment une arrivée sera classée.
class StaffArrivalPreview extends StatelessWidget {
  final StaffArrivalClass result;
  final StaffAttendanceSettings settings;

  const StaffArrivalPreview({
    super.key,
    required this.result,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(result.status);
    final late = result.status == StaffAttendanceStatus.late;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        children: [
          Icon(tone.icon, color: tone.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              late
                  ? l10n.staffAttendancePreviewLate(
                      result.lateMinutes,
                      settings.start.wire,
                      settings.toleranceMinutes,
                    )
                  : l10n.staffAttendancePreviewOnTime(settings.lastOnTime.wire),
              style: AppTypography.bodyMedium.copyWith(color: tone.ink),
            ),
          ),
        ],
      ),
    );
  }
}
