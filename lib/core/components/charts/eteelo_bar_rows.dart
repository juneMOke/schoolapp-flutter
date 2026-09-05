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

  const EteeloBarRows({
    super.key,
    required this.rows,
    this.barHeight = AppDimensions.enrollmentDashboardRowBarHeight,
    this.labelWidth = AppDimensions.enrollmentDashboardRowLabelWidth,
  });

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<num>(0, (sum, row) => sum + row.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimensions.spacingS),
          _Row(
            row: rows[i],
            fraction: total <= 0 ? 0 : rows[i].value / total,
            barHeight: barHeight,
            labelWidth: labelWidth,
          ),
        ],
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
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
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
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
