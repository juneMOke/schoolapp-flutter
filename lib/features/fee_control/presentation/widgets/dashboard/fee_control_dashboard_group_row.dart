import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne du classement : un groupe, sa part d'élèves en ordre, son effectif.
///
/// **Une seule ligne pour les deux mailles.** Un niveau et une de ses classes
/// se lisent exactement pareil — c'est la même mesure, d'un cran plus fin — et
/// deux widgets auraient fini par les afficher différemment.
///
/// **Toutes les barres portent la même teinte.** Colorer chacune selon sa
/// valeur doublerait l'encodage de la longueur par la couleur, et peindrait un
/// jugement là où le classement suffit : ce qui décroche est déjà en tête de
/// liste. La couleur reste donc libre de ne rien dire, et les tokens de statut
/// gardent leur sens, qui est le statut d'un élève.
class FeeControlDashboardGroupRow extends StatelessWidget {
  final String label;
  final FeeControlBreakdown breakdown;

  /// Maille fine (une classe sous son niveau) : mêmes informations, moins d'air
  /// et une typographie secondaire.
  final bool dense;

  /// Déplie ou replie ce groupe. `null` rend la ligne inerte — c'est le cas des
  /// classes, qui n'ont rien sous elles, et du groupe « niveau non renseigné »,
  /// qui n'a pas de classe où chercher.
  final VoidCallback? onToggle;

  final bool expanded;

  /// Ouvre l'écran nominatif sur ce groupe. `null` quand il n'y a personne à
  /// nommer — le groupe « niveau non renseigné », qui n'a pas de niveau à
  /// transmettre.
  final VoidCallback? onOpenControl;

  const FeeControlDashboardGroupRow({
    super.key,
    required this.label,
    required this.breakdown,
    this.dense = false,
    this.onToggle,
    this.expanded = false,
    this.onOpenControl,
  });

  /// Épaisseur de la barre. Fine à dessein : une barre épaisse lit « bloc »
  /// plutôt que « mesure », et l'air autour d'elle fait la lisibilité de la
  /// liste.
  static const double _barHeight = 8;
  static const double _denseBarHeight = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final percent = breakdown.settledPercent;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onToggle != null)
              Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: dense
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            // La valeur au bout, jamais dans la barre : une barre courte
            // rognerait son propre libellé.
            Text(
              '$percent %',
              style:
                  (dense
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.titleSmall)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              l10n.feeControlDashboardGroupTally(
                breakdown.settled,
                breakdown.total,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        _Bar(percent: percent, dense: dense),
      ],
    );

    // La ligne s'annonce d'une phrase — nom, part, effectif — au lieu de faire
    // épeler quatre fragments dont l'ordre n'a de sens qu'à l'œil.
    final described = Semantics(
      container: true,
      button: onToggle != null,
      // ⚠️ **L'action, pas seulement le rôle.** La ligne s'annonçait « bouton »
      // et portait un `InkWell` — mais celui-ci était sous `ExcludeSemantics` :
      // le nœud n'exposait donc AUCUNE action, et la double-tape d'un lecteur
      // d'écran ne dépliait rien. Un rôle sans action, c'est un bouton qui
      // ment.
      onTap: onToggle,
      label: l10n.feeControlDashboardGroupA11y(
        label,
        percent,
        breakdown.settled,
        breakdown.total,
      ),
      hint: onToggle == null
          ? null
          : (expanded
                ? l10n.feeControlDashboardCollapse
                : l10n.feeControlDashboardExpand),
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
          // ⚠️ **Hors du sous-arbre exclu.** Enfermé dedans, comme il l'était,
          // le bouton disparaissait de l'arbre sémantique : la ligne
          // s'annonçait, mais son action restait inatteignable au lecteur
          // d'écran. C'est un geste DISTINCT du dépliage — il doit s'annoncer
          // à part.
          if (onOpenControl != null)
            IconButton(
              onPressed: onOpenControl,
              icon: const Icon(Icons.people_outline),
              iconSize: dense ? 18 : 20,
              visualDensity: VisualDensity.compact,
              tooltip: l10n.feeControlDashboardOpenControl,
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final int percent;
  final bool dense;

  const _Bar({required this.percent, required this.dense});

  @override
  Widget build(BuildContext context) {
    final height = dense
        ? FeeControlDashboardGroupRow._denseBarHeight
        : FeeControlDashboardGroupRow._barHeight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: percent / 100,
        minHeight: height,
        backgroundColor: AppColors.accueilFeeControlSoft,
        valueColor: const AlwaysStoppedAnimation<Color>(
          AppColors.accueilFeeControlAccent,
        ),
      ),
    );
  }
}
