import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryStudentCompactHeader extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String cycleName;
  final String levelName;
  final String classroomName;

  const DisciplinaryStudentCompactHeader({
    super.key,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.cycleName,
    required this.levelName,
    required this.classroomName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _buildDisplayName(l10n);
    final displayCycle = cycleName.trim().isEmpty
        ? l10n.disciplinaryUnknownValue
        : cycleName.trim();
    final displayLevel = levelName.trim().isEmpty
        ? l10n.disciplinaryUnknownValue
        : levelName.trim();
    final displayClassroom = classroomName.trim().isEmpty
        ? l10n.disciplinaryUnknownValue
        : classroomName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          StudentAvatar(
            firstName: firstName,
            lastName: lastName,
            size: AppDimensions.detailMiniIconSize + AppDimensions.spacingL,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontFamily: 'Lora',
                    color: AppColors.bleuArdoise,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  '$displayCycle / $displayLevel / $displayClassroom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
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

  String _buildDisplayName(AppLocalizations l10n) {
    final fullName = [
      lastName,
      middleName,
      firstName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? l10n.disciplinaryUnknownValue : fullName;
  }
}
