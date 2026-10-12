import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_preview_text.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/announcement_category_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La page que le bouton WhatsApp ouvre : le texte complet, rendu pour la
/// famille d'exemple, avec le liseré de sa catégorie.
class ReadingPagePreview extends StatelessWidget {
  final AnnouncementContent content;
  final String? schoolName;

  const ReadingPagePreview({super.key, required this.content, this.schoolName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = categoryTone(content.category);
    final body = l10n.readingPreview(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppColors.bleuProfond,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.subMenuAnnouncements.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.orDoux,
                ),
              ),
              Text(
                schoolName ?? l10n.communicationSampleSchool,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border(left: BorderSide(color: tone.ink, width: 4)),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnnouncementCategoryChip(category: content.category),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.readingTitle(content),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body.isEmpty ? l10n.communicationPreviewEmptyBody : body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: body.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.communicationPreviewSignature(
                      schoolName ?? l10n.communicationSampleSchool,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
