import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un bandeau d'une ligne dans un formulaire : avertissement non bloquant
/// (ambre) ou erreurs à corriger (rouge).
class StaffNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color ink;
  final Color background;

  const StaffNotice._(this.message, this.icon, this.ink, this.background);

  factory StaffNotice.warning(String message) => StaffNotice._(
    message,
    Icons.info_outline,
    AppColors.staffPartialInk,
    AppColors.feeStatusPartialSoft,
  );

  factory StaffNotice.error(String message) => StaffNotice._(
    message,
    Icons.error_outline,
    AppColors.error,
    AppColors.feeStatusDueSoft,
  );

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(color: background, borderRadius: AppRadius.brMd),
    child: Row(
      children: [
        Icon(icon, size: 18, color: ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: ink),
          ),
        ),
      ],
    ),
  );
}
