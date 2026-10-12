import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_category_chip.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un modèle : catégorie, titre, extrait de trois lignes, les champs qu'il
/// insère, et ses gestes. Sans [onEdit] ni [onDelete], la carte ne propose
/// que « Utiliser ».
class TemplateCard extends StatelessWidget {
  final AnnouncementTemplate template;
  final VoidCallback? onUse;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TemplateCard({
    super.key,
    required this.template,
    this.onUse,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final variables = AnnouncementVariables.usedIn(
      '${template.title} ${template.body}',
    );
    final use = onUse;
    final edit = onEdit;
    final delete = onDelete;
    return CommunicationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnnouncementCategoryChip(category: template.category),
          const SizedBox(height: AppSpacing.sm),
          Text(
            template.title.isEmpty
                ? l10n.communicationUntitled
                : template.title,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            template.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (variables.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final variable in variables)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      l10n.variableLabel(variable),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.terreCuiteDark,
                      ),
                    ),
                    backgroundColor: AppColors.terreCuiteSoft,
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (use != null)
                EteeloButton.secondary(
                  label: l10n.communicationTemplateUse,
                  icon: Icons.arrow_forward,
                  onPressed: use,
                  size: EteeloButtonSize.compact,
                  fullWidth: false,
                ),
              if (edit != null)
                EteeloButton.ghost(
                  label: l10n.communicationTemplateEdit,
                  icon: Icons.edit_outlined,
                  onPressed: edit,
                  size: EteeloButtonSize.compact,
                  fullWidth: false,
                ),
              if (delete != null)
                EteeloButton.ghost(
                  label: l10n.communicationDelete,
                  icon: Icons.delete_outline,
                  onPressed: delete,
                  size: EteeloButtonSize.compact,
                  fullWidth: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
