import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';

/// Contenus d'une carte KPI — un par habillage.
///
/// Les deux ne partagent rien : sur une carte claire la valeur porte l'accent
/// et le libellé passe **sous** elle ; sur un pavé plein la valeur est crème et
/// le libellé passe **au-dessus**, en capitales. Les fondre en un seul widget
/// paramétré donnerait une succession de ternaires sans lecture possible.

/// Contenu de la carte claire — l'habillage historique.
///
/// ⚠️ Reproduit à l'identique : ses hauteurs sont assertées au pixel par
/// `eteelo_kpi_card_test.dart` (104 dp, 128 dp avec sous-ligne, + 22 dp par
/// valeur supplémentaire). Toute retouche ici casse ces mesures.
class EteeloKpiCardPlainContent extends StatelessWidget {
  final EteeloKpiCardData data;

  const EteeloKpiCardPlainContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = data.displayValues;

    return Column(
      // `min` : la hauteur vient du contenu, le plancher du `Container`.
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXS),
              decoration: BoxDecoration(
                color: data.accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(data.icon, size: 14, color: data.accent),
            ),
            const Spacer(),
            if (data.percent != null)
              Text(
                '${data.percent} %',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        // Une valeur par ligne. `scaleDown` ne réduit que si la largeur
        // manque, donc les compteurs entiers courts restent inchangés — et
        // deux devises gardent chacune sa taille pleine au lieu d'être
        // rétrécies ensemble sur une ligne unique.
        for (final value in values)
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                // ⚠️ La valeur passe par le garde-fou, pas par l'accent brut.
                //
                // L'accent peint aussi le liseré et le médaillon, où il est
                // lisible et porte le sens — l'ambre dit « justifié », l'or dit
                // « électricité ». Mais posé sur du BLANC en 24 dp gras, l'or
                // tombe à 2,28:1 et l'ambre à 2,82:1. Et sur la bande des
                // Dépenses, cet accent vient du **serveur** : aucune relecture
                // ne verra le défaut, qui ne se déclenche que chez les écoles
                // dont le poste dominant est celui-là.
                //
                // Corriger ici plutôt qu'à chaque appel : les quatre bandes de
                // KPI du produit en bénéficient, et la cinquième aussi.
                style: AppTextStyles.pageTitle.copyWith(
                  color: DashboardTones.encreLisible(data.accent),
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ),
        // Sans sous-ligne : label sur deux lignes au plus. Avec sous-ligne :
        // label compact (1 ligne) + sous-ligne discrète, sur une carte plus
        // haute.
        if (data.subline == null)
          Text(
            data.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        else ...[
          Text(
            data.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.subline!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Contenu d'un pavé plein (spec couleurs §03).
///
/// Toutes les encres sont **opaques** : sur un fond assombri, une encre
/// translucide retombe sous le seuil dès que l'accent s'éclaircit.
class EteeloKpiCardFilledContent extends StatelessWidget {
  final EteeloKpiCardData data;

  const EteeloKpiCardFilledContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = data.displayValues;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              // ⚠️ L'or **clair**, pas `orDoux`.
              //
              // Un glyphe est un objet graphique : le seuil est 3:1, plus bas
              // que pour du texte, mais il s'applique. `orDoux` #D9A24E ne le
              // franchit que sur le pavé le plus bleu (3,00, tout juste) et
              // tombe à 2,33 sur le vert, 1,97 sur la terre cuite, 1,93 sur
              // l'ocre — et baisser le voile n'y change rien, puisqu'à voile
              // nul trois fonds sur cinq échouent encore.
              //
              // Le commentaire précédent annonçait « toléré à 3,5:1 » : ce
              // chiffre valait pour les seuls pavés bleus d'Inscriptions, et
              // il est devenu faux dès qu'un pavé vert ou ocre est apparu.
              child: Icon(
                data.icon,
                size: AppDimensions.insPaveMedallionIconSize,
                color: AppColors.orSurPave,
              ),
            ),
            const SizedBox(width: AppDimensions.insPaveHeaderGap),
            // Les capitales sont une affaire de **rendu**, pas de contenu :
            // Flutter n'ayant pas de `text-transform`, il faut majusculer la
            // chaîne — mais un lecteur d'écran épelle volontiers un mot tout
            // en capitales. On annonce donc le libellé tel qu'il est écrit, et
            // on n'affiche que sa version capitalisée.
            Expanded(
              child: Semantics(
                label: data.label,
                child: ExcludeSemantics(
                  child: Text(
                    data.label.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppDimensions.insPaveLabelFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: AppDimensions.insPaveLabelLetterSpacing,
                      color: AppColors.insInkLabel,
                    ),
                  ),
                ),
              ),
            ),
            if (data.percent != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '${data.percent} %',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.insInkSub,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        for (var i = 0; i < values.length; i++)
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                values[i],
                maxLines: 1,
                // La première valeur porte l'encre pleine. Les suivantes — une
                // seconde devise — prennent la nuance du pavé quand l'appelant
                // en fournit une, et l'encre pleine sinon : le défaut reste
                // identique à l'octet pour les cartes qui n'en déclarent pas.
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppDimensions.insPaveValueFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  color: i == 0
                      ? AppColors.insInkMain
                      : (data.filledSecondaryInk ?? AppColors.insInkMain),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        if (data.subline != null) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            data.subline!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: AppDimensions.insPaveSublineFontSize,
              fontWeight: FontWeight.w400,
              height: 1.45,
              color: AppColors.insInkSub,
            ),
          ),
        ],
      ],
    );
  }
}

/// Disque de lumière ancré hors du coin haut droit d'un pavé, sous le contenu.
/// Purement décoratif — il donne du relief à l'aplat sans rien signifier.
class EteeloKpiCardHalo extends StatelessWidget {
  const EteeloKpiCardHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppDimensions.insPaveHaloTop,
      right: AppDimensions.insPaveHaloRight,
      width: AppDimensions.insPaveHaloSize,
      height: AppDimensions.insPaveHaloSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.insInkMain.withValues(
            alpha: EteeloKpiCard.filledHaloVeil,
          ),
        ),
      ),
    );
  }
}
