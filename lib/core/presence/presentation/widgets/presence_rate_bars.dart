import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/components/charts/chart_entrance.dart';
import 'package:school_app_flutter/core/components/charts/chart_label_density.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const BorderRadius _radius = BorderRadius.all(
  Radius.circular(AppDimensions.presenceRateBarRadius),
);

/// Une barre du graphique : un jour, ou un mois.
class PresenceRateBarData {
  /// Sous l'axe : « lun. 19 », « 19 », « oct. ».
  final String label;

  /// Infobulle et libellé d'accessibilité, phrase entière : la date, les
  /// présents, les absents.
  final String description;

  /// Part des agents pointés venus (à l'heure ou en retard), en % ; `null`
  /// quand personne n'est pointé — la barre se dessine alors en pointillés,
  /// sans chiffre.
  final int? presencePct;

  const PresenceRateBarData({
    required this.label,
    required this.description,
    required this.presencePct,
  });
}

/// Le graphique de présence bichrome : chaque barre est **pleine hauteur**
/// et se lit d'un coup d'œil — vert en bas pour les présents, rouge au-dessus
/// pour les absents, taux écrit au-dessus de la barre.
///
/// La couleur ne porte jamais seule l'information : le taux est écrit, et
/// chaque barre a sa phrase pour le lecteur d'écran et l'appui long.
///
/// Pas de fl_chart ici : une barre de hauteur fixe à deux segments n'a ni
/// axe ni domaine à calculer, et des widgets simples portent chacun leur
/// infobulle et leur sémantique.
class PresenceRateBars extends StatelessWidget {
  final List<PresenceRateBarData> bars;

  const PresenceRateBars({super.key, required this.bars});

  /// Sous cette largeur de barre, le taux s'écrit sans « % » — la légende le
  /// dit une fois pour toutes ([isNarrow]).
  static bool isNarrow(double barWidth) =>
      barWidth < AppDimensions.presenceRateBarNarrowWidth;

  /// La largeur d'une barre pour [count] barres sur [width] dp.
  static double barWidthFor({required int count, required double width}) {
    if (count <= 0 || !width.isFinite) return AppDimensions.presenceRateBarMax;
    return (width / count * AppDimensions.presenceRateBarWidthShare).clamp(
      AppDimensions.presenceRateBarMin,
      AppDimensions.presenceRateBarMax,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final barWidth = barWidthFor(count: bars.length, width: width);
        final step = chartLabelStep(
          count: bars.length,
          width: width,
          minSpacing: AppDimensions.presenceRateBarLabelSpacing,
        );
        return ChartEntrance(
          builder: (context, motion) => SizedBox(
            height: AppDimensions.presenceRateBarsHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: _Bar(
                      bar: bars[i],
                      width: barWidth,
                      showLabel: i % step == 0,
                      progress: motion.progress,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final PresenceRateBarData bar;
  final double width;
  final bool showLabel;
  final double progress;

  const _Bar({
    required this.bar,
    required this.width,
    required this.showLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = bar.presencePct;
    final narrow = PresenceRateBars.isNarrow(width);
    final present = PresenceTone.of(PresenceStatus.present);
    return Semantics(
      container: true,
      label: bar.description,
      excludeSemantics: true,
      child: Tooltip(
        message: bar.description,
        // Au doigt, l'appui long ; à la souris, le survol.
        triggerMode: TooltipTriggerMode.longPress,
        child: Column(
          children: [
            SizedBox(
              height: AppDimensions.presenceRateBarValueHeight,
              child: pct == null
                  ? null
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        narrow ? '$pct' : l10n.presenceRateValue(pct),
                        style:
                            (narrow
                                    ? AppTypography.labelSmall
                                    : AppTypography.labelMedium)
                                .copyWith(
                                  color: present.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: pct == null
                      ? const _EmptyBar()
                      : _Segments(pct: pct, progress: progress, wide: !narrow),
                ),
              ),
            ),
            SizedBox(
              height: AppDimensions.presenceRateBarAxisHeight,
              child: showLabel
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bar.label,
                        maxLines: 1,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vert en bas (p / n), rouge au-dessus ; le taux d'absence s'écrit dans le
/// rouge quand il y a la place.
class _Segments extends StatelessWidget {
  final int pct;
  final double progress;
  final bool wide;

  const _Segments({
    required this.pct,
    required this.progress,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final absentPct = 100 - pct;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // L'entrée fait monter le vert depuis la base ; le rouge occupe le
        // reste, la barre garde sa pleine hauteur.
        final green = height * pct / 100 * progress;
        final red = height - green;
        final absentLabel =
            wide &&
            absentPct > 0 &&
            height * absentPct / 100 >=
                AppDimensions.presenceRateBarAbsentLabelMinHeight;
        return ClipRRect(
          borderRadius: _radius,
          child: Column(
            children: [
              Container(
                height: red,
                color: AppColors.presenceMarkAbsent,
                alignment: Alignment.topCenter,
                child: absentLabel
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.presenceRateValue(absentPct),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.presenceMarkOnBanner,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              Container(height: green, color: AppColors.presenceMarkPresent),
            ],
          ),
        );
      },
    );
  }
}

/// Un jour sans pointage : voile et pointillés du statut « à pointer ».
class _EmptyBar extends StatelessWidget {
  const _EmptyBar();

  @override
  Widget build(BuildContext context) {
    final none = PresenceTone.of(PresenceStatus.none);
    return DecoratedBox(
      decoration: BoxDecoration(color: none.soft, borderRadius: _radius),
      child: CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: none.border,
          borderRadius: _radius,
          strokeWidth: 1,
          dash: 4,
          gap: 3,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
