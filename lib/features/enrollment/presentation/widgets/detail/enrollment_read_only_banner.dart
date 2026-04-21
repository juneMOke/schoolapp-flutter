import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum EnrollmentDetailAccessMode { readOnly, editable }

class EnrollmentReadOnlyBanner extends StatelessWidget {
  final EnrollmentDetailAccessMode mode;

  const EnrollmentReadOnlyBanner({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditable = mode == EnrollmentDetailAccessMode.editable;
    final accentColor = isEditable
        ? const Color(0xFF059669)
        : const Color(0xFFEA580C);
    final iconColor = isEditable
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);
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
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            isEditable ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
            (isEditable ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5))
                .withValues(alpha: 0.88),
          ],
        ),
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
              borderRadius: BorderRadius.circular(8),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppTheme.textSecondaryColor,
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
