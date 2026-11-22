import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Un pavé du bloc B (`RecHero` de la maquette) : libellé, un montant par
/// devise, sous-ligne — et, sur « Perçu à ce jour » en une seule devise,
/// l'anneau du taux perçu.
///
/// ⚠️ Écart assumé au socle : le pavé plein d'[EteeloKpiCard] n'a pas
/// d'anneau, et on ne change pas un composant partagé pour un seul écran. Ce
/// pavé en reprend donc l'habillage à l'identique — jetons `insPave*`, halo
/// [EteeloKpiCardHalo], fond [DashboardTones.pave], encres crème — et
/// n'ajoute que l'anneau.
class RecoveryFigurePave extends StatelessWidget {
  final String label;
  final IconData icon;

  /// Le sens du pavé (attendu, encaissé, marque) — le fond en dérive.
  final Color accent;

  /// Un montant par devise, dollars d'abord ; jamais additionnés.
  final List<String> values;
  final String subline;

  /// Le taux perçu, ou `null` : pas d'anneau (mixte, ou rien d'attendu).
  final int? ringPercent;
  final String? ringLabel;
  final String? ringSemantics;

  const RecoveryFigurePave({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.values,
    required this.subline,
    this.ringPercent,
    this.ringLabel,
    this.ringSemantics,
  });

  @override
  Widget build(BuildContext context) {
    final safeAccent = DashboardTones.paveAccentSur(accent);
    final secondInk = DashboardTones.encreSecondeValeur(safeAccent);

    return Container(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.insPaveMinHeight,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DashboardTones.pave(safeAccent),
        borderRadius: BorderRadius.circular(AppDimensions.insPaveRadius),
        boxShadow: DashboardTones.paveShadow,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: AppDimensions.spacingS),
                for (var i = 0; i < values.length; i++)
                  // Un montant ne passe jamais à la ligne ni ne se coupe : il
                  // se réduit dans sa largeur (spec §4.1, texte ×1,3).
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        values[i],
                        maxLines: 1,
                        style: AppTextStyles.totalAmountLora.copyWith(
                          fontSize: AppDimensions.insPaveValueFontSize,
                          height: 1.05,
                          color: i == 0 ? AppColors.insInkMain : secondInk,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  subline,
                  style: AppTextStyles.kpiPaveSubline.copyWith(
                    color: AppColors.insInkSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        width: AppDimensions.insPaveMedallionSize,
        height: AppDimensions.insPaveMedallionSize,
        decoration: BoxDecoration(
          color: AppColors.insInkMain.withValues(
            alpha: EteeloKpiCard.filledMedallionVeil,
          ),
          borderRadius: BorderRadius.circular(
            AppDimensions.insPaveMedallionRadius,
          ),
        ),
        child: Icon(
          icon,
          size: AppDimensions.insPaveMedallionIconSize,
          color: AppColors.orSurPave,
        ),
      ),
      const SizedBox(width: AppDimensions.insPaveHeaderGap),
      // Le libellé peut passer à la ligne (§4.1) ; capitales de rendu seulement.
      Expanded(
        child: Semantics(
          label: label,
          header: true,
          child: ExcludeSemantics(
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.badge.copyWith(
                fontSize: AppDimensions.insPaveLabelFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: AppDimensions.insPaveLabelLetterSpacing,
                color: AppColors.insInkLabel,
              ),
            ),
          ),
        ),
      ),
      if (ringPercent case final percent?) ...[
        const SizedBox(width: AppDimensions.spacingS),
        _RateRing(
          percent: percent,
          label: ringLabel ?? '$percent',
          semantics: ringSemantics,
        ),
      ],
    ],
  );
}

/// L'anneau du taux perçu : piste voilée, arc or doux, taux au centre.
class _RateRing extends StatelessWidget {
  final int percent;
  final String label;
  final String? semantics;

  const _RateRing({required this.percent, required this.label, this.semantics});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = (percent / 100).clamp(0.0, 1.0);

    Widget ringAt(double t) => CustomPaint(
      painter: _RingPainter(fraction: target * t),
      child: Center(
        // Le taux ne passe jamais à la ligne : il se réduit dans l'anneau.
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.recoveryRateRingStroke),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.badge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.insInkMain,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: semantics ?? label,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppDimensions.recoveryRateRingSize,
          child: reduceMotion
              ? ringAt(1)
              : TweenAnimationBuilder<double>(
                  key: ValueKey<int>(percent),
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: AppMotion.layout,
                  curve: AppMotion.outCurve,
                  builder: (context, t, _) => ringAt(t),
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  /// Voile de la piste (`rgba(255,255,255,.18)` de la maquette).
  static const double _trackVeil = 0.18;

  final double fraction;

  const _RingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = AppDimensions.recoveryRateRingStroke;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.insInkMain.withValues(alpha: _trackVeil);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = DashboardSense.prestige;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
