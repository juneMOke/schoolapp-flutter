import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Carte KPI générique affichant un indicateur chiffré avec accent couleur.
///
/// Deux habillages, choisis par la donnée seule :
///
/// * **carte claire** (défaut) — surface blanche, liseré d'accent à gauche,
///   valeur en couleur d'accent. C'est l'habillage de tous les tableaux de
///   bord existants, et il ne bouge pas d'un pixel.
/// * **pavé plein** — quand [EteeloKpiCardData.filledBackground] est fourni :
///   aplat sombre, encres crème opaques, halo et médaillon voilés. Introduit
///   par le tableau de bord des inscriptions, où la rangée de chiffres clés
///   doit se distinguer d'une page par ailleurs entièrement claire.
class EteeloKpiCard extends StatelessWidget {
  final EteeloKpiCardData data;

  const EteeloKpiCard({super.key, required this.data});

  /// Voile du médaillon d'un pavé plein.
  static const double filledMedallionVeil = 0.14;

  /// Voile du halo d'un pavé plein.
  static const double filledHaloVeil = 0.07;

  /// Opacité de l'ombre portée d'un pavé plein.
  ///
  /// L'ombre reste **bleu profond** quelle que soit la teinte du pavé : une
  /// ombre ocre sous un pavé ocre le ferait flotter dans une flaque de sa
  /// propre couleur.
  static const double filledShadowOpacity = 0.18;

  /// Le tour d'une carte enfoncée. Transparent au repos : le rendu des cartes
  /// de lecture ne bouge pas d'un pixel.
  static BorderSide _edge(EteeloKpiCardData data) =>
      data.selected ? BorderSide(color: data.accent) : BorderSide.none;

  double get _radius => data.isFilled
      ? AppDimensions.insPaveRadius
      : AppDimensions.enrollmentStatsChartRadius;

  @override
  Widget build(BuildContext context) {
    final card = data.isFilled ? _buildFilled() : _buildPlain();
    final tapped = _wrapTap(card);

    // reduced-motion : pas d'animation d'entree (etat final visible).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return tapped;

    return TweenAnimationBuilder<double>(
      key: ValueKey('${data.label}-${data.displayValue}-${data.percent}'),
      tween: Tween(begin: 0.97, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.outCurve,
      builder: (context, scale, child) => Opacity(
        opacity: scale,
        child: Transform.scale(scale: scale, child: child),
      ),
      child: tapped,
    );
  }

  /// Hauteur plancher, jamais fixe : la carte garde son gabarit quand le
  /// contenu y tient, et grandit quand il n'y tient plus — un second montant,
  /// une police agrandie par le téléphone. Fixée d'avance, elle débordait.
  BoxConstraints _constraints() {
    if (data.isFilled) {
      return const BoxConstraints(
        minWidth: AppDimensions.enrollmentStatsKpiCardMinWidth,
        minHeight: AppDimensions.insPaveMinHeight,
      );
    }
    final baseHeight = data.subline != null
        ? AppDimensions.kpiCardHeightWithSubline
        : AppDimensions.enrollmentStatsKpiCardHeight;
    final extraValues = data.displayValues.length - 1;
    return BoxConstraints(
      minWidth: AppDimensions.enrollmentStatsKpiCardMinWidth,
      minHeight:
          baseHeight + extraValues * AppDimensions.kpiCardExtraValueHeight,
    );
  }

  Widget _buildPlain() {
    return Container(
      constraints: _constraints(),
      // Le contenu reste centré verticalement dans le plancher, comme avant.
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.enrollmentStatsCardSurface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border(
          left: BorderSide(color: data.accent, width: 3),
          // Enfoncée : le tour de la carte reprend l'accent. Jamais la couleur
          // seule — l'état est aussi annoncé, et la valeur reste écrite.
          top: _edge(data),
          right: _edge(data),
          bottom: _edge(data),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: EteeloKpiCardPlainContent(data: data),
    );
  }

  /// Le pavé n'a **pas** de liseré d'accent : sa teinte porte déjà l'identité
  /// du chiffre. Un bord transparent de 1 dp tient la réserve de gabarit, pour
  /// que l'état enfoncé puisse l'occuper sans décaler le contenu.
  Widget _buildFilled() {
    return Container(
      constraints: _constraints(),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: data.filledBackground,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: data.selected ? AppColors.orDoux : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bleuProfond.withValues(alpha: filledShadowOpacity),
            blurRadius: AppDimensions.insPaveShadowBlur,
            offset: const Offset(0, AppDimensions.insPaveShadowOffsetY),
          ),
        ],
      ),
      child: Stack(
        children: [
          const EteeloKpiCardHalo(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.insPavePaddingH,
              AppDimensions.insPavePaddingTop,
              AppDimensions.insPavePaddingH,
              AppDimensions.insPavePaddingBottom,
            ),
            child: EteeloKpiCardFilledContent(data: data),
          ),
        ],
      ),
    );
  }

  /// N'enveloppe que les cartes qui **font** quelque chose : l'arbre d'une
  /// carte de lecture reste exactement celui d'avant.
  Widget _wrapTap(Widget card) {
    final onTap = data.onTap;
    if (onTap == null) return card;

    return Semantics(
      button: true,
      selected: data.selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: card,
      ),
    );
  }
}
