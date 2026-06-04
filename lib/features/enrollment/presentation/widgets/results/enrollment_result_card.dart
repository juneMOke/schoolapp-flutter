import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultCard extends StatelessWidget {
  final EnrollmentSummary enrollment;
  final VoidCallback onTap;
  final VoidCallback? onViewDetails;

  const EnrollmentResultCard({
    super.key,
    required this.enrollment,
    required this.onTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = EnrollmentStatus.fromString(enrollment.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brCard,
          border: Border.all(color: AppColors.border),
          boxShadow: AppElevation.shadowCard,
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: avatar + names + action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                core_avatar.StudentAvatar(
                  firstName: enrollment.student.firstName,
                  lastName: enrollment.student.lastName,
                  size: 48,
                  variant: _avatarVariantForStatus(status),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enrollment.student.lastName,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        enrollment.student.firstName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                if (onViewDetails != null)
                  IconButton(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility_outlined),
                    color: AppColors.bleuArdoise,
                    tooltip: l10n.viewDetails,
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            // Info row: date of birth
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dateOfBirth,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  _formatDate(enrollment.student.dateOfBirth),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.enable('tnum')],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            // Status badge
            Row(
              children: [
                Text(
                  l10n.enrollmentStatusFilterLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(child: EnrollmentStatusBadge(status: status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  core_avatar.AvatarVariant _avatarVariantForStatus(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.completed ||
      EnrollmentStatus.validated => core_avatar.AvatarVariant.solid,
      _ => core_avatar.AvatarVariant.outlined,
    };
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }
}
