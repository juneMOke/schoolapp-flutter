import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create/disciplinary_create_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de la modale « Nouveau cas » : le marteau, le titre, et la croix
/// — retirée pendant l'enregistrement, qu'on ne puisse fermer en plein envoi.
class DisciplinaryCreateHeader extends StatelessWidget {
  final bool isLoading;

  const DisciplinaryCreateHeader({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.disciplinaryDetailAccentSoft,
            AppColors.disciplinaryDetailTealSoft,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.sectionCardRadius),
          topRight: Radius.circular(AppDimensions.sectionCardRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.spacingXL + AppDimensions.spacingXS,
            height: AppDimensions.spacingXL + AppDimensions.spacingXS,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            ),
            child: const Icon(
              Icons.gavel_outlined,
              size: AppDimensions.detailHeaderIconSize,
              color: AppColors.disciplinaryDetailAccent,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.disciplinaryCaseCreateDialogTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.disciplinaryDetailAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isLoading)
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}

/// Le statut que prendra le cas : toujours « Ouvert » à la création.
class DisciplinaryCreateStatusBlock extends StatelessWidget {
  const DisciplinaryCreateStatusBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const open = DisciplinaryCaseStatus.open;
    final color = open.getColor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisciplinaryCreateFieldLabel(l10n.disciplinaryStatusAtCreationLabel),
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.disciplinaryStatusPillPaddingH,
              vertical: AppDimensions.disciplinaryStatusPillPaddingV,
            ),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: AppDimensions.disciplinaryTintAlpha,
              ),
              borderRadius: AppRadius.brPill,
              border: Border.all(
                color: color.withValues(
                  alpha: AppDimensions.disciplinaryTintBorderAlpha,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  open.getIcon(),
                  size: AppDimensions.disciplinaryStatusPillIconSize,
                  color: color,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  open.getDisplayName(l10n),
                  style: AppTextStyles.badge.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.disciplinaryStatusAtCreationHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
