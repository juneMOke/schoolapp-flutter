import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';

class FinanceStatsChartCard extends StatelessWidget {
  /// `null` en chargement : le titre y est un bloc, pas un mot.
  final String? title;

  /// Le repère de la carte, posé **avant** le titre.
  ///
  /// ⚠️ **Elle double le titre, elle ne le remplace jamais.** Le titre reste
  /// écrit en toutes lettres et porte seul le sens ; l'icône sert à retrouver
  /// la carte d'un coup d'œil dans une page qui en empile six. Elle n'entre
  /// donc pas dans l'arbre d'accessibilité — un lecteur d'écran annoncerait
  /// deux fois la même chose.
  final IconData? icon;

  /// Une action posée **au bout de la ligne de titre** — un export, jamais une
  /// navigation. `null` sur la plupart des cartes : celles de cet écran sont
  /// des lectures, et n'offrent rien à faire.
  final Widget? trailing;

  final Widget child;

  /// Assez petite pour rester sous la hauteur de la ligne de titre : au-delà,
  /// l'icône pousserait la ligne de séparation vers le bas et la carte ne
  /// s'alignerait plus sur sa voisine.
  static const double _iconSize = 18;

  const FinanceStatsChartCard({
    super.key,
    required String this.title,
    this.icon,
    this.trailing,
    required this.child,
  });

  /// Le **même cadre**, avec un bloc à la place du titre.
  ///
  /// Une copie du cadre dans le squelette dériverait du vrai au premier
  /// ajustement de rayon ou d'ombre — et le contenu sauterait en arrivant, ce
  /// que le squelette existe précisément pour éviter. Ici le cadre est le même
  /// objet ; seule sa première ligne change.
  const FinanceStatsChartCard.skeleton({super.key, required this.child})
    : title = null,
      icon = null,
      trailing = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title case final title?)
            Row(
              children: [
                if (icon case final icon?) ...[
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: _iconSize,
                      color: AppColors.bleuArdoise,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                ],
                // Un titre long se coupe plutôt que de déborder : les cartes se
                // rangent maintenant deux par ligne, et « Créances réglées en
                // FC » y dispose de la moitié de la largeur.
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing case final trailing?) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  trailing,
                ],
              ],
            )
          else
            // La hauteur du titre réel, pour que la ligne de séparation et tout
            // ce qui suit ne bouge pas d'un pixel à l'arrivée des données.
            const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: EteeloSkeletonBox(width: 180, height: 14),
              ),
            ),
          const SizedBox(height: AppDimensions.spacingS),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.spacingM),
          child,
        ],
      ),
    );
  }
}
