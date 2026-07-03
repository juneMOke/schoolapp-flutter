import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/matiere_score.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/resultats_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Points forts / à renforcer (spec §7) : top 3 et bottom 3 des matières par %.
/// Masqué si aucune matière n'est disponible.
class ResultatFocusMatieres extends StatelessWidget {
  final List<MatiereScore> topMatieres;
  final List<MatiereScore> bottomMatieres;

  const ResultatFocusMatieres({
    super.key,
    required this.topMatieres,
    required this.bottomMatieres,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (topMatieres.isEmpty && bottomMatieres.isEmpty) {
      return const SizedBox.shrink();
    }
    return ResultatsCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          if (topMatieres.isNotEmpty)
            _MatiereColumn(
              icon: Icons.auto_awesome_outlined,
              accent: AppColors.vertSavane,
              title: l10n.resultatsStrengthsTitle,
              matieres: topMatieres,
            ),
          if (bottomMatieres.isNotEmpty)
            _MatiereColumn(
              icon: Icons.trending_up_rounded,
              accent: AppColors.terreCuite,
              title: l10n.resultatsWeaknessesTitle,
              matieres: bottomMatieres,
            ),
        ],
      ),
    );
  }
}

class _MatiereColumn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final List<MatiereScore> matieres;

  const _MatiereColumn({
    required this.icon,
    required this.accent,
    required this.title,
    required this.matieres,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.bleuProfond,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final matiere in matieres)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      matiere.brancheNom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    resultatsPercent(l10n, matiere.pourcentage),
                    style: AppTypography.labelMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
