import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPendingDistributionCard extends StatelessWidget {
  final bool isDistributing;
  final int studentsToDistribute;
  final int plannedClassroomCount;
  final VoidCallback onDistributionRequested;

  const ClassesOrganisationPendingDistributionCard({
    required this.isDistributing,
    required this.studentsToDistribute,
    required this.plannedClassroomCount,
    required this.onDistributionRequested,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesOrganisationDashedContainer(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.borderStrong.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.terreCuite.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.terreCuite,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.classesOrganisationPendingTitle,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.classesOrganisationPendingSubtitle,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: [
              ClassesOrganisationInfoChip(
                icon: Icons.groups_outlined,
                text: l10n.classesOrganisationPendingStudentsToDistribute(
                  studentsToDistribute,
                ),
              ),
              ClassesOrganisationInfoChip(
                icon: Icons.grid_view_rounded,
                text: l10n.classesOrganisationPendingPlannedClassrooms(
                  plannedClassroomCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FilledButton.icon(
            onPressed: isDistributing ? null : onDistributionRequested,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.terreCuite,
              foregroundColor: AppColors.blancCasse,
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
              shape: const StadiumBorder(),
            ),
            icon: isDistributing
                ? const SizedBox(
                    width: AppDimensions.detailMiniIconSize,
                    height: AppDimensions.detailMiniIconSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(l10n.classesOrganisationDistributionAction),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: AppColors.classesInfoBannerSurface,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              border: Border.all(color: AppColors.classesInfoBannerBorder),
            ),
            child: Text(
              l10n.classesOrganisationAppliedCriterionInfo,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
