import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum EnrollmentDetailAccessMode { readOnly, editable }

class EnrollmentReadOnlyBanner extends StatelessWidget {
  final EnrollmentDetailAccessMode mode;

  const EnrollmentReadOnlyBanner({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditable = mode == EnrollmentDetailAccessMode.editable;
    final accentColor = isEditable ? AppColors.success : AppColors.warning;
    final iconColor = accentColor;
    final title = isEditable
        ? l10n.enrollmentEditableTitle
        : l10n.enrollmentReadOnlyTitle;
    final message = isEditable
        ? l10n.enrollmentEditableMessage
        : l10n.enrollmentReadOnlyMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              isEditable ? Icons.edit_rounded : Icons.visibility_outlined,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
