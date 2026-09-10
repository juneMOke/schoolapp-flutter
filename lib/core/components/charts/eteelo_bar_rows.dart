import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Une ligne de [EteeloBarRows].
class EteeloBarRow {
  /// Libellé de gauche — tronqué à l'ellipse s'il dépasse sa colonne.
  final String label;

  /// Poids de la barre.
  final num value;

  /// Valeur écrite à droite, déjà formatée et accordée par l'appelant.
  final String valueLabel;

  final Color color;

  /// Ouvre le détail de cette ligne. `null` rend la ligne non cliquable — et
  /// alors sans curseur ni effet d'appui, pour ne pas promettre un geste qui
  /// n'existe pas.
  final VoidCallback? onTap;

  /// Phrase lue à la place de la ligne. `null` compose « libellé, valeur ».
  final String? semanticsLabel;

  const EteeloBarRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.color,
    this.onTap,
    this.semanticsLabel,
  });
}

/// Ce dont la barre d'une ligne montre la part.
///
/// Les deux répondent à des questions différentes, et aucune n'est un défaut
/// universel :
///
/// * [byTotal] — « quelle **proportion de l'ensemble** cette ligne
///   représente-t-elle ». Deux cartes de la même page restent comparables, et
///   la somme des barres remplit la largeur. C'est ce que veut une
///   répartition.
/// * [byMax] — « comment cette ligne se compare-t-elle **à la plus forte** ».
///   La première barre est toujours pleine, et l'œil lit un classement plutôt
///   qu'une part. C'est ce que veut un palmarès.
///
/// La contrepartie de [byTotal] est assumée dans la doc de la classe : sur une
/// répartition très étalée, les petites barres deviennent des traits — d'où
/// [EteeloBarRows.minimumFraction].
enum EteeloBarRowsScale { byTotal, byMax }

/// Un classement en lignes-barres : libellé, barre, valeur.
///
/// Répond à « où » — quelle catégorie pèse combien — là où un anneau répondrait
/// mal : au-delà de cinq ou six parts, un donut devient une légende que l'œil
/// doit rapprocher de secteurs qu'il ne sait plus mesurer. Une école aligne
/// facilement une douzaine de niveaux.
///
/// ## La largeur des barres : une part, pas un maximum
///
/// Chaque barre occupe sa **part du total**, et non sa part du plus grand. Un
/// niveau à 40 % d'un effectif dessine 40 % de la largeur : la barre se lit
/// comme une proportion, et deux cartes de la même page restent comparables.
///
/// La contrepartie est assumée : sur une répartition très étalée — un niveau à
/// 60 %, dix autres à 4 % — les petites barres deviennent des traits. C'est une
/// lecture juste (ces niveaux *sont* marginaux), et la valeur chiffrée reste
/// écrite à droite de chacune.
class EteeloBarRows extends StatelessWidget {
  final List<EteeloBarRow> rows;

  /// Épaisseur d'une barre.
  final double barHeight;

  /// Largeur de la colonne des libellés.
  final double labelWidth;

  /// Ce dont la barre montre la part — voir [EteeloBarRowsScale].
  final EteeloBarRowsScale scale;

  /// Largeur plancher d'une barre non nulle, en fraction.
  ///
  /// Une valeur réelle mais minuscule doit **rester visible** : sans plancher,
  /// une ligne à 0,4 % rend un trait d'un pixel qu'on prend pour une absence.
  /// Zéro reste zéro — le plancher ne s'applique qu'au-dessus.
  final double minimumFraction;

  const EteeloBarRows({
    super.key,
    required this.rows,
    this.barHeight = AppDimensions.enrollmentDashboardRowBarHeight,
    this.labelWidth = AppDimensions.enrollmentDashboardRowLabelWidth,
    this.scale = EteeloBarRowsScale.byTotal,
    this.minimumFraction = 0,
  });

  @override
  Widget build(BuildContext context) {
    final reference = switch (scale) {
      EteeloBarRowsScale.byTotal => rows.fold<num>(
        0,
        (sum, row) => sum + row.value,
      ),
      EteeloBarRowsScale.byMax => rows.fold<num>(
        0,
        (best, row) => row.value > best ? row.value : best,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimensions.spacingS),
          _Row(
            row: rows[i],
            fraction: _fractionOf(rows[i].value, reference),
            barHeight: barHeight,
            labelWidth: labelWidth,
          ),
        ],
      ],
    );
  }

  /// La part d'une valeur, plancher compris — **et zéro reste zéro**.
  double _fractionOf(num value, num reference) {
    if (reference <= 0 || value <= 0) return 0;
    final fraction = value / reference;
    return fraction < minimumFraction ? minimumFraction : fraction;
  }
}

class _Row extends StatelessWidget {
  final EteeloBarRow row;
  final double fraction;
  final double barHeight;
  final double labelWidth;

  const _Row({
    required this.row,
    required this.fraction,
    required this.barHeight,
    required this.labelWidth,
  });

  /// Part maximale de la rangée que le libellé peut prendre quand son gabarit
  /// de 132 dp ne tient plus.
  ///
  /// La valeur est **mesurée, pas choisie** : à 0,42 la rangée débordait encore
  /// d'un demi-pixel à 320 dp — un demi-pixel qui affiche quand même la bande
  /// jaune et noire. 0,38 laisse la marge, et garde au libellé plus du tiers de
  /// la rangée, ce qui reste lisible.
  static const double _labelShare = 0.38;

  @override
  Widget build(BuildContext context) {
    // ⚠️ **Le libellé cède, le montant jamais.**
    //
    // La rangée additionne un libellé figé à 132 dp, deux gouttières et un
    // montant de taille intrinsèque. Sous une certaine largeur, cette somme
    // dépasse la place disponible, la barre `Expanded` tombe à zéro et la
    // rangée déborde quand même — dix-neuf pixels à 320 dp, mesuré.
    //
    // Quelque chose doit donc céder, et ce n'est pas négociable lequel : rendre
    // le **montant** flexible le tronquerait, et un chiffre tronqué est un
    // chiffre faux. C'est le libellé qui se contente d'une part de la rangée et
    // s'élide — un libellé élidé se devine, et il est répété dans la légende.
    final content = LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: constraints.maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingXS,
          ),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth.isFinite
                      ? math.min(labelWidth, constraints.maxWidth * _labelShare)
                      : labelWidth,
                ),
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _Bar(
                  color: row.color,
                  fraction: fraction,
                  height: barHeight,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Text(
                row.valueLabel,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: row.onTap != null,
      label: row.semanticsLabel ?? '${row.label}, ${row.valueLabel}',
      onTap: row.onTap,
      child: ExcludeSemantics(
        child: row.onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: row.onTap,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                  child: content,
                ),
              ),
      ),
    );
  }
}

/// La barre elle-même, sur sa piste.
///
/// La piste reste visible sous la barre : c'est elle qui donne l'échelle, et
/// c'est elle qu'on lit quand une valeur est nulle.
class _Bar extends StatelessWidget {
  final Color color;
  final double fraction;
  final double height;

  const _Bar({
    required this.color,
    required this.fraction,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget barAt(double t) => ClipRRect(
      borderRadius: BorderRadius.circular(
        AppDimensions.enrollmentDashboardPillRadius,
      ),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: AppColors.surfaceAlt,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (fraction * t).clamp(0.0, 1.0),
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );

    if (reduceMotion) return barAt(1);

    return TweenAnimationBuilder<double>(
      key: ValueKey<double>(fraction),
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.layout,
      curve: AppMotion.outCurve,
      builder: (context, t, _) => barAt(t),
    );
  }
}
