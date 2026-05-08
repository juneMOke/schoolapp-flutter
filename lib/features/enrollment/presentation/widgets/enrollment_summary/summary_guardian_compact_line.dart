import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_mini_avatar.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryGuardianCompactLine extends StatelessWidget {
  final ParentSummary parent;
  final bool isPrimary;
  final String relationshipLabel;

  const SummaryGuardianCompactLine({
    super.key,
    required this.parent,
    required this.isPrimary,
    required this.relationshipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullName = [
      parent.firstName,
      parent.lastName,
      parent.surname ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SummaryMiniAvatar(
            firstName: parent.firstName,
            lastName: parent.lastName,
            size: 32,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isPrimary)
                      StatusBadge(
                        icon: Icons.star_rounded,
                        label: l10n.guardianPrincipalBadge,
                        color: AppColors.bleuArdoise,
                        size: StatusBadgeSize.small,
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  [
                    relationshipLabel,
                    parent.phoneNumber,
                  ].where((part) => part.trim().isNotEmpty).join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
