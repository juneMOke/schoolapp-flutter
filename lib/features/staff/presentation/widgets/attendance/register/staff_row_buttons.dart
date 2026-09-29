import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// Les boutons d'icône d'une ligne du registre : effacer, ± heure, renvoyer.

/// Un bouton d'icône carré de 36 dp (effacer, réessayer, ± heure).
class StaffSquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const StaffSquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppDimensions.staffAttendanceIconButtonSize,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      iconSize: AppSpacing.lg + AppSpacing.xs,
      color: color ?? AppColors.textSecondary,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}

/// Un pointage refusé : son motif, et de quoi le renvoyer.
class StaffRetryButton extends StatelessWidget {
  final StaffAttendanceRecord record;
  final VoidCallback onRetry;

  const StaffRetryButton({
    super.key,
    required this.record,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (record.syncState != StaffSyncState.failed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return StaffSquareIconButton(
      icon: Icons.refresh,
      color: AppColors.staffAttendanceAbsentInk,
      tooltip:
          '${StaffAttendanceLabels.refusal(l10n, record)} — '
          '${l10n.staffAttendanceRetry}',
      onPressed: onRetry,
    );
  }
}
