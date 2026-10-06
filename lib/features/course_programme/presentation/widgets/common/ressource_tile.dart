import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/ressource_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Une ressource en une ligne : icône du type, intitulé, « Type · détail »
/// (ellipse), et un geste à droite (retirer, ouvrir).
class RessourceTile extends StatelessWidget {
  final RessourceType type;
  final String nom;
  final String? detail;
  final Widget? trailing;
  final Widget? badge;

  const RessourceTile({
    super.key,
    required this.type,
    required this.nom,
    this.detail,
    this.trailing,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = RessourceVisual.label(l10n, type);
    final subtitle = detail == null || detail!.isEmpty
        ? typeLabel
        : l10n.ressourceDetail(typeLabel, detail!);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              RessourceVisual.icon(type),
              size: ProgrammeLayout.iconSmall,
              color: AppColors.bleuArdoise,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  badge!,
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
