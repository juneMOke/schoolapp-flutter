import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_rate_ring.dart';

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
        RecoveryRateRing(
          percent: percent,
          label: ringLabel ?? '$percent',
          semantics: ringSemantics,
        ),
      ],
    ],
  );
}
