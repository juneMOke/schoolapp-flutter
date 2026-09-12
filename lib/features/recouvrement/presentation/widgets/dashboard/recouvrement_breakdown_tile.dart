import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_tri_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de « Où en est chaque niveau » : un cycle, ou un niveau sous son
/// cycle — son nom, la part qui a tout payé, la barre tricolore et ses comptes.
///
/// **Une seule ligne pour les deux mailles.** Un cycle et un de ses niveaux se
/// lisent pareil — c'est la même mesure, d'un cran plus fin — et deux widgets
/// auraient fini par les afficher différemment.
class RecouvrementBreakdownTile extends StatelessWidget {
  final String label;
  final FeeControlBreakdown breakdown;

  /// Maille fine (un niveau sous son cycle) : mêmes informations, barre plus
  /// fine et typographie secondaire.
  final bool dense;

  /// Ouvre ou referme le cycle. `null` rend la ligne inerte — c'est le cas des
  /// niveaux, qui n'ont rien sous eux.
  final VoidCallback? onToggle;

  final bool expanded;

  /// L'œil : ouvre le contrôle nominatif sur ce niveau. `null` quand il n'y a
  /// pas de périmètre à transmettre — ligne sans niveau, ou niveau que le
  /// référentiel ne rattache à aucun cycle. Un œil qui n'ouvrirait rien
  /// mentirait.
  final VoidCallback? onView;

  const RecouvrementBreakdownTile({
    super.key,
    required this.label,
    required this.breakdown,
    this.dense = false,
    this.onToggle,
    this.expanded = false,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final percent = breakdown.settledPercent;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onToggle != null) ...[
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: AppDimensions.recouvrementChevronSize,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dense ? AppTextStyles.body : AppTextStyles.bodyStrong,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            // La part qui a TOUT payé, dans la teinte de sa part de barre. Au
            // bout de la ligne, jamais dans la barre : une part courte y
            // rognerait son propre chiffre.
            Text(
              l10n.recouvrementSettledPercent(percent),
              style: AppTextStyles.bodyStrong.copyWith(
                color: RecouvrementTriColors.settled,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        RecouvrementTriBar(breakdown: breakdown, dense: dense),
        const SizedBox(height: AppDimensions.spacingXS),
        RecouvrementTriCounts(breakdown: breakdown, dense: dense),
      ],
    );

    // La ligne s'annonce d'une phrase — nom, trois comptes, part — au lieu de
    // faire épeler des fragments dont l'ordre n'a de sens qu'à l'œil.
    final described = Semantics(
      container: true,
      button: onToggle != null,
      // ⚠️ L'action, pas seulement le rôle : sous `ExcludeSemantics`, l'InkWell
      // n'expose rien. C'est ce nœud-ci qui porte le geste, sans quoi la
      // double-tape d'un lecteur d'écran n'ouvrirait rien.
      onTap: onToggle,
      label: l10n.recouvrementBreakdownA11y(
        label,
        breakdown.settled,
        breakdown.total,
        percent,
        breakdown.partial,
        breakdown.none,
      ),
      hint: onToggle == null
          ? null
          : (expanded
                ? l10n.recouvrementCycleCollapse
                : l10n.recouvrementCycleExpand),
      child: ExcludeSemantics(
        child: onToggle == null ? info : InkWell(onTap: onToggle, child: info),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: dense ? AppDimensions.spacingXS : AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          Expanded(child: described),
          // Hors du sous-arbre exclu : c'est un geste DISTINCT du dépliage, et
          // il doit s'annoncer à part.
          if (onView != null) ...[
            const SizedBox(width: AppDimensions.spacingS),
            _ViewButton(label: label, onPressed: onView!),
          ],
        ],
      ),
    );
  }
}

/// L'œil, teinté pour se lire comme un bouton et non comme une décoration.
class _ViewButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ViewButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      onPressed: onPressed,
      // Le niveau est dans le nom du geste : dix yeux alignés qui disent tous
      // « Voir » ne diraient pas au lecteur d'écran lequel il ouvre.
      tooltip: l10n.recouvrementLevelView(label),
      icon: const Icon(Icons.visibility_outlined),
      iconSize: AppDimensions.recouvrementViewIconSize,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bleuArdoiseSoft,
        foregroundColor: AppColors.bleuArdoise,
        minimumSize: const Size.square(
          AppDimensions.recouvrementViewButtonSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        ),
      ),
    );
  }
}
