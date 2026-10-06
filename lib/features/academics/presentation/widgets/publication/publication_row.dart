import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/publication_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de publication (spec S6) : ce qui se publie, son état, ce qui
/// part ou ce qui manque, et « Publier » ou « Retirer ».
class PublicationRow extends StatelessWidget {
  final String title;
  final PublicationEtat? etat;

  /// Ce qui est publié, ou pourquoi ce n'est pas possible.
  final String? description;

  /// Publier : `null` = bouton désactivé (motif dans [description]).
  final VoidCallback? onPublish;
  final VoidCallback? onWithdraw;
  final bool busy;

  /// L'élément ne se publie pas (sujet d'une interrogation) : pastille
  /// « En classe » à la place des actions.
  final bool inClass;

  const PublicationRow({
    super.key,
    required this.title,
    required this.etat,
    required this.onPublish,
    required this.onWithdraw,
    this.description,
    this.busy = false,
    this.inClass = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final etat = this.etat;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.publicationRowTextMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (inClass)
                      NotationPill(
                        color: AppColors.textSecondary,
                        soft: AppColors.surfaceAlt,
                        label: l10n.publicationInClass,
                      )
                    else if (etat != null)
                      NotationPill(
                        color: AppColors.academicsScoreGood,
                        soft: AppColors.academicsScoreGoodSoft,
                        icon: Icons.check_circle_outline_rounded,
                        label: publicationEtatLabel(context, etat),
                      )
                    else
                      NotationPill(
                        color: AppColors.textSecondary,
                        soft: AppColors.surfaceAlt,
                        label: l10n.publicationNotPublished,
                      ),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!inClass)
            etat != null
                ? EteeloButton.secondary(
                    label: l10n.publicationWithdraw,
                    icon: Icons.undo_rounded,
                    fullWidth: false,
                    isLoading: busy,
                    onPressed: busy ? null : onWithdraw,
                  )
                : EteeloButton.primary(
                    label: l10n.publicationPublish,
                    icon: Icons.send_rounded,
                    fullWidth: false,
                    isLoading: busy,
                    onPressed: busy ? null : onPublish,
                  ),
        ],
      ),
    );
  }
}
