import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Un segment de [EteeloSplitBar].
///
/// [value] donne la **proportion** (la largeur), [valueLabel] donne le **texte**
/// (« 182 · 51 % »). Les deux sont séparés parce qu'ils ne servent pas la même
/// chose : la largeur se calcule, le libellé se traduit et s'accorde en nombre.
/// Le composant ne formate rien — l'accord singulier/pluriel et la locale
/// appartiennent à l'appelant, qui a l10n sous la main.
class EteeloSplitBarSegment {
  final String label;
  final String valueLabel;
  final num value;
  final Color color;

  const EteeloSplitBarSegment({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });
}

/// Barre empilée 100 % suivie de sa légende — « qui », en une ligne.
///
/// Reprise du tableau de bord des présences, où elle a été mise au point, et
/// portée au socle pour son deuxième appelant (répartition filles/garçons et
/// premières/réinscriptions du tableau de bord des inscriptions).
///
/// ## Ce que le composant garantit
///
/// * **Aucune information n'est portée par la seule couleur.** Chaque segment
///   écrit son libellé et sa valeur dans la légende, et le label a11y de la
///   barre les répète tous — un lecteur d'écran n'a pas à deviner ce que
///   « la part bleue » vaut.
/// * **Un total nul reste lisible.** Zéro partout ne dessine pas une barre
///   vide et muette : la piste s'affiche, la légende annonce ses zéros. C'est
///   un état, pas une absence de rendu.
/// * Le remplissage est **animé** à l'arrivée des données, et l'animation
///   disparaît sous `prefers-reduced-motion`.
class EteeloSplitBar extends StatelessWidget {
  final List<EteeloSplitBarSegment> segments;

  /// Phrase lue par les lecteurs d'écran à la place du tracé. Doit porter
  /// toutes les valeurs : c'est le seul équivalent textuel de la barre.
  final String semanticsLabel;

  /// Épaisseur de la barre. 16 dp par défaut ; 9 dp pour une barre de ligne
  /// enchâssée dans une liste.
  final double height;

  const EteeloSplitBar({
    super.key,
    required this.segments,
    required this.semanticsLabel,
    this.height = AppDimensions.enrollmentDashboardSplitBarHeight,
  });

  /// Somme des proportions. Zéro quand rien n'a été compté.
  num get _total => segments.fold<num>(0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBar(context),
        const SizedBox(height: AppDimensions.spacingM),
        _buildLegend(),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final total = _total;

    // Les flex sont des entiers : on travaille au millième du total pour que
    // deux segments proches ne s'égalisent pas à l'arrondi.
    const precision = 1000;
    final flexes = [
      for (final segment in segments)
        total <= 0 ? 0 : (segment.value * precision / total).round(),
    ];

    Widget barAt(double t) {
      final filled = flexes.fold<int>(0, (sum, f) => sum + f);
      final spacerFlex = (filled * (1 - t)).round();
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentDashboardPillRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(
          // La piste reste visible sous les segments : c'est elle qui porte
          // l'état « rien à répartir ».
          color: AppColors.surfaceAlt,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Row(
              // ⚠️ `stretch`, et ce n'est pas cosmétique : les segments sont
              // des `ColoredBox` SANS enfant. Sous l'alignement par défaut
              // (`center`), un Row donne à ses enfants des contraintes
              // transversales lâches, et une boîte sans enfant s'y effondre à
              // zéro de haut. La barre affichait alors sa piste grise avec des
              // segments à la bonne largeur mais invisibles — pendant que la
              // légende, elle, écrivait ses valeurs. D'où « la barre est
              // vide » avec des chiffres justes juste en dessous.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < segments.length; i++)
                  if (flexes[i] > 0)
                    Expanded(
                      flex: (flexes[i] * t).round().clamp(0, precision),
                      child: Tooltip(
                        message:
                            '${segments[i].label} · ${segments[i].valueLabel}',
                        child: ColoredBox(color: segments[i].color),
                      ),
                    ),
                if (spacerFlex > 0)
                  Expanded(flex: spacerFlex, child: const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: reduceMotion
            ? barAt(1)
            : TweenAnimationBuilder<double>(
                key: ValueKey<String>(
                  segments.map((s) => '${s.label}:${s.value}').join('|'),
                ),
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppMotion.layout,
                curve: AppMotion.outCurve,
                builder: (context, t, _) => barAt(t),
              ),
      ),
    );
  }

  /// Pastille + libellé + valeur, la valeur teintée comme son segment.
  ///
  /// Exclue du lecteur d'écran : la barre porte déjà la phrase complète, et
  /// relire chaque segment ferait entendre deux fois la même répartition.
  Widget _buildLegend() {
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppDimensions.spacingL,
        runSpacing: AppDimensions.spacingS,
        children: [
          for (final segment in segments)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppDimensions.spacingS + 3,
                  height: AppDimensions.spacingS + 3,
                  decoration: BoxDecoration(
                    color: segment.color,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.spacingXS,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  segment.label,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  segment.valueLabel,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: segment.color,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
