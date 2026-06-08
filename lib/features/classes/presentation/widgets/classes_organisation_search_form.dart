import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_applied_criterion_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_cascading_selectors.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'en-tête de la composition des classes : eyebrow (terre-cuite) +
/// titre, puis les deux Select en cascade (Cycle → Niveau) et le critère de
/// répartition appliqué.
class ClassesOrganisationSearchForm extends StatelessWidget {
  final String schoolYear;
  final List<ClassesOrganisationCycleOption> cycles;
  final String? selectedCycleId;
  final String? selectedLevelId;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<ClassesOrganisationLevelOption?> onLevelChanged;

  const ClassesOrganisationSearchForm({
    super.key,
    required this.schoolYear,
    required this.cycles,
    required this.selectedCycleId,
    required this.selectedLevelId,
    required this.onCycleChanged,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.classesOrganisationShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.classesOrganisationHeaderEyebrow(schoolYear).toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.classesOrganisationSearchTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ClassesOrganisationCascadingSelectors(
            cycles: cycles,
            selectedCycleId: selectedCycleId,
            selectedLevelId: selectedLevelId,
            onCycleChanged: onCycleChanged,
            onLevelChanged: onLevelChanged,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClassesOrganisationAppliedCriterionCard(
            label: l10n.classesOrganisationDistributionLabel,
            value: l10n.classesOrganisationDistributionByGender,
          ),
        ],
      ),
    );
  }
}
