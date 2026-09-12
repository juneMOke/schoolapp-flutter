import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois teintes de « Où en est chaque niveau », dites une seule fois :
/// **vert** tout payé, **jaune** payé en partie, **rouge** rien payé.
///
/// Ce sont les tokens de statut, et c'est exactement leur sens ici : le statut
/// d'un élève sur les frais retenus.
abstract final class RecouvrementTriColors {
  static const settled = AppColors.vertSavane;
  static const partial = AppColors.warning;
  static const none = AppColors.error;
}

/// La répartition d'un groupe en trois parts — tout payé, en partie, rien —,
/// **à la proportion exacte de ses élèves**.
///
/// Une part vide n'est pas dessinée : un liseré de couleur pour zéro élève
/// dirait qu'il y en a. Les parts sont séparées d'un liseré de fond pour se
/// distinguer aussi sans la couleur ; leur sens, lui, est écrit en toutes
/// lettres sous la barre ([RecouvrementTriCounts]), jamais porté par la seule
/// teinte.
class RecouvrementTriBar extends StatelessWidget {
  final FeeControlBreakdown breakdown;

  /// Barre fine : un niveau sous son cycle.
  final bool dense;

  const RecouvrementTriBar({
    super.key,
    required this.breakdown,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = [
      (breakdown.settled, RecouvrementTriColors.settled),
      (breakdown.partial, RecouvrementTriColors.partial),
      (breakdown.none, RecouvrementTriColors.none),
    ].where((part) => part.$1 > 0).toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        AppDimensions.recouvrementTriBarRadius,
      ),
      child: SizedBox(
        width: double.infinity,
        height: dense
            ? AppDimensions.recouvrementTriBarDenseHeight
            : AppDimensions.recouvrementTriBarHeight,
        child: parts.isEmpty
            // Un groupe sans élève n'existe pas au classement : la piste nue
            // est une ceinture, pas un état qu'on s'attend à voir.
            ? const ColoredBox(color: AppColors.surfaceAlt)
            : Row(
                // `stretch` : sans lui, une part sans enfant prendrait la
                // hauteur minimale — zéro — et la barre serait invisible.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0)
                      const SizedBox(
                        width: AppDimensions.recouvrementTriBarGap,
                      ),
                    Expanded(
                      flex: parts[i].$1,
                      child: ColoredBox(color: parts[i].$2),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Les trois comptes, puis l'effectif : ce que la barre montre, dit en toutes
/// lettres.
///
/// Les trois sont toujours écrits, zéro compris : « 0 rien payé » est une
/// information — la meilleure qui soit —, et une ligne dont les comptes
/// changeraient de place d'un niveau à l'autre ne se lirait plus en colonne.
class RecouvrementTriCounts extends StatelessWidget {
  final FeeControlBreakdown breakdown;
  final bool dense;

  const RecouvrementTriCounts({
    super.key,
    required this.breakdown,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = (dense ? AppTextStyles.caption : AppTextStyles.body).copyWith(
      color: AppColors.textSecondary,
      fontFeatures: AppTextStyles.tabularFigures,
    );

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Count(
          color: RecouvrementTriColors.settled,
          text: l10n.recouvrementCountSettled(breakdown.settled),
          style: style,
        ),
        _Count(
          color: RecouvrementTriColors.partial,
          text: l10n.recouvrementCountPartial(breakdown.partial),
          style: style,
        ),
        _Count(
          color: RecouvrementTriColors.none,
          text: l10n.recouvrementCountNone(breakdown.none),
          style: style,
        ),
        Text(
          l10n.recouvrementCountTotal(breakdown.total),
          style: style.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final Color color;
  final String text;
  final TextStyle style;

  const _Count({required this.color, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimensions.recouvrementCountDot,
          height: AppDimensions.recouvrementCountDot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(text, style: style),
      ],
    );
  }
}
