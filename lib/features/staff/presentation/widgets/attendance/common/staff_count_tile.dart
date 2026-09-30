import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';

/// Un compteur dans la teinte d'un statut : le résumé du rapport journalier,
/// et les indicateurs de la fiche mensuelle.
class StaffCountTile extends StatelessWidget {
  final StaffAttendanceStatus tone;
  final String label;
  final String value;
  final String? detail;

  const StaffCountTile({
    super.key,
    required this.tone,
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StaffAttendanceTone.of(tone);
    final detail = this.detail;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(colors.icon, size: AppSpacing.lg, color: colors.ink),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(color: colors.ink),
          ),
          if (detail != null)
            Text(
              detail,
              style: AppTypography.bodySmall.copyWith(color: colors.ink),
            ),
        ],
      ),
    );
  }
}
