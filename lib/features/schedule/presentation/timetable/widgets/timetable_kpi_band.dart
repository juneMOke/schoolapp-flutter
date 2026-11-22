import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_parts.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La bande de pavés d'un emploi du temps (EDT §4.6 B) : une grille fluide
/// (`minmax(148, 1fr)`, colonnes vides repliées) où « En cours » prend deux
/// colonnes — toute la ligne sur un téléphone ([wideFullRow]).
class TimetableKpiBand extends StatelessWidget {
  final List<EteeloKpiCardData> cards;

  /// Le pavé « En cours », s'il y en a un.
  final Widget? wide;
  final bool wideFullRow;

  const TimetableKpiBand({
    super.key,
    required this.cards,
    this.wide,
    this.wideFullRow = false,
  });

  @override
  Widget build(BuildContext context) {
    const gap = AppDimensions.spacingM;
    const min = AppDimensions.enrollmentStatsKpiCardMinWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fit = ((width + gap) / (min + gap)).floor().clamp(1, 99);
        final wide = this.wide;
        final wideSpan = wide == null ? 0 : (wideFullRow ? fit : 2);
        final columns = (cards.length + wideSpan).clamp(1, fit);
        final cell = ((width - gap * (columns - 1)) / columns).floorToDouble();
        final wideWidth = wideFullRow || columns < 2 ? width : cell * 2 + gap;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: cell,
                child: EteeloKpiCard(data: card),
              ),
            if (wide != null) SizedBox(width: wideWidth, child: wide),
          ],
        );
      },
    );
  }
}

/// Le pavé « En cours » (marque) : sa valeur est un **texte** — le cours, sur
/// deux lignes au plus — que le pavé du socle rétrécirait sur une ligne.
/// Même habillage que les pavés pleins (halo, médaillon, encres crème).
class TimetableNowPave extends StatelessWidget {
  final String label;
  final String value;
  final String? subline;

  /// Une séance a lieu maintenant : la pastille remplace l'icône.
  final bool live;

  const TimetableNowPave({
    super.key,
    required this.label,
    required this.value,
    this.subline,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = DashboardTones.pave(
      DashboardTones.paveAccentSur(DashboardSense.marque),
    );
    return Semantics(
      container: true,
      label: [label, value, ?subline].join(' · '),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.insPaveMinHeight,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppDimensions.insPaveRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.bleuProfond.withValues(
                alpha: EteeloKpiCard.filledShadowOpacity,
              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Medallion(live: live),
                      const SizedBox(width: AppDimensions.insPaveHeaderGap),
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppDimensions.insPaveLabelFontSize,
                            fontWeight: FontWeight.w500,
                            letterSpacing:
                                AppDimensions.insPaveLabelLetterSpacing,
                            color: AppColors.insInkLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      fontSize: AppDimensions.timetableNowPaveValueFontSize,
                      height: 1.2,
                      color: AppColors.insInkMain,
                    ),
                  ),
                  if (subline case final sub?) ...[
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.kpiPaveSubline.copyWith(
                        color: AppColors.insInkSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  final bool live;

  const _Medallion({required this.live});

  @override
  Widget build(BuildContext context) => Container(
    width: AppDimensions.insPaveMedallionSize,
    height: AppDimensions.insPaveMedallionSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.insInkMain.withValues(
        alpha: EteeloKpiCard.filledMedallionVeil,
      ),
      borderRadius: BorderRadius.circular(AppDimensions.insPaveMedallionRadius),
    ),
    child: live
        ? Container(
            width: AppDimensions.timetableNowDot,
            height: AppDimensions.timetableNowDot,
            decoration: const BoxDecoration(
              color: AppColors.timetableHeaderInk,
              shape: BoxShape.circle,
            ),
          )
        : const Icon(
            Icons.schedule_outlined,
            size: AppDimensions.insPaveMedallionIconSize,
            color: AppColors.orSurPave,
          ),
  );
}
