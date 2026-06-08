import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// État « Niveau non réparti » (PARCOURS 3).
///
/// Le niveau a des élèves mais aucun n'est rattaché à une classe. On l'explicite
/// (titre + message), on rappelle l'effectif et le ratio G/F, puis on propose la
/// répartition automatique par genre via un unique bouton primaire.
class ClassesOrganisationPendingDistributionCard extends StatelessWidget {
  final bool isDistributing;
  final ClassroomStatus overviewStatus;
  final String levelName;
  final int studentsToDistribute;
  final int maleCount;
  final int femaleCount;
  final VoidCallback onDistributionRequested;

  const ClassesOrganisationPendingDistributionCard({
    required this.isDistributing,
    required this.overviewStatus,
    required this.levelName,
    required this.studentsToDistribute,
    required this.maleCount,
    required this.femaleCount,
    required this.onDistributionRequested,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoadingOverview =
        overviewStatus == ClassroomStatus.loading ||
        overviewStatus == ClassroomStatus.initial;

    return ClassesOrganisationDashedContainer(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.borderStrong.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.terreCuite.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.groups_outlined,
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
                      l10n.classesOrganisationPendingMessage(
                        studentsToDistribute,
                        levelName,
                      ),
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
          _PendingHeadcountRecap(
            isLoading: isLoadingOverview,
            studentsToDistribute: studentsToDistribute,
            maleCount: maleCount,
            femaleCount: femaleCount,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FilledButton.icon(
            onPressed: (isDistributing || isLoadingOverview)
                ? null
                : onDistributionRequested,
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
            label: Text(l10n.classesOrganisationDistributeByGenderAction),
          ),
        ],
      ),
    );
  }
}

/// Encart « Rappel » : effectif + pastilles Garçons (bleu) / Filles (terre-cuite).
class _PendingHeadcountRecap extends StatelessWidget {
  final bool isLoading;
  final int studentsToDistribute;
  final int maleCount;
  final int femaleCount;

  const _PendingHeadcountRecap({
    required this.isLoading,
    required this.studentsToDistribute,
    required this.maleCount,
    required this.femaleCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: AppDimensions.spacingL,
                height: AppDimensions.spacingL,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ClassesOrganisationStatChip(
                  icon: Icons.groups_outlined,
                  label: l10n.classesOrganisationPendingStudentsToDistribute(
                    studentsToDistribute,
                  ),
                  background: AppColors.surface,
                  foreground: AppColors.textPrimary,
                ),
                ClassesOrganisationGenderPill(
                  label: l10n.classesOrganisationGenderBoysPill(maleCount),
                  color: AppColors.bleuArdoise,
                ),
                ClassesOrganisationGenderPill(
                  label: l10n.classesOrganisationGenderGirlsPill(femaleCount),
                  color: AppColors.terreCuite,
                ),
              ],
            ),
    );
  }
}
