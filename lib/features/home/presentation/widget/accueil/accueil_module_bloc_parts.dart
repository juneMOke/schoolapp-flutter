import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/home/domain/entity/accueil_module.dart';
import 'package:school_app_flutter/features/home/presentation/widget/accueil/accueil_ui_tokens.dart';

/// Pièces d'habillage d'un pavé module (spec Accueil-Couleurs §05).
///
/// Aucune de ces surfaces n'introduit de couleur : ce sont des **voiles de
/// blanc cassé** posés sur le fond du module, plus le glyphe d'accent du
/// médaillon. Elles ne portent aucun geste — le pavé garde la navigation.

/// Médaillon, titre, nombre de pages et flèche.
class AccueilModuleBlocHeaderRow extends StatelessWidget {
  final AccueilModule module;
  final bool isHovered;
  final String pageCountLabel;

  const AccueilModuleBlocHeaderRow({
    super.key,
    required this.module,
    required this.isHovered,
    required this.pageCountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AccueilModuleBlocMedallion(module: module, isHovered: isHovered),
        const SizedBox(width: AccueilUiTokens.blocMedaillonToTitleGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: AccueilUiTokens.blocTitleFontSize,
                  fontWeight: FontWeight.w600,
                  height: AccueilUiTokens.blocTitleHeight,
                  color: AppColors.accueilBlocInkMain,
                ),
              ),
              const SizedBox(height: AccueilUiTokens.blocMetaGapTop),
              Text(
                pageCountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AccueilUiTokens.blocMetaFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accueilBlocInkMeta,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AccueilUiTokens.blocMedaillonToTitleGap),
        AnimatedSlide(
          duration: AppMotion.medium,
          curve: AppMotion.outCurve,
          // `AnimatedSlide.offset` s'exprime en fractions de la taille de
          // l'enfant : on convertit le décalage cible (3 dp) en fraction de la
          // largeur de l'icône.
          offset: Offset(
            isHovered
                ? AccueilUiTokens.blocArrowHoverShift /
                      AccueilUiTokens.blocArrowSize
                : 0,
            0,
          ),
          child: const Icon(
            Icons.arrow_forward,
            size: AccueilUiTokens.blocArrowSize,
            color: AppColors.accueilBlocInkMain,
          ),
        ),
      ],
    );
  }
}

/// Médaillon d'icône : voile de blanc cassé, bord translucide, glyphe en
/// couleur d'accent. Il se dilate légèrement au survol du pavé.
class AccueilModuleBlocMedallion extends StatelessWidget {
  final AccueilModule module;
  final bool isHovered;

  const AccueilModuleBlocMedallion({
    super.key,
    required this.module,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppMotion.medium,
      curve: AppMotion.outCurve,
      scale: isHovered ? AccueilUiTokens.blocMedaillonHoverScale : 1,
      child: Container(
        width: AccueilUiTokens.blocMedaillonSize,
        height: AccueilUiTokens.blocMedaillonSize,
        decoration: BoxDecoration(
          color: AppColors.accueilBlocInkMain.withValues(
            alpha: AccueilUiTokens.blocMedaillonVeil,
          ),
          borderRadius: BorderRadius.circular(
            AccueilUiTokens.blocMedaillonRadius,
          ),
          border: Border.all(
            color: AppColors.accueilBlocInkMain.withValues(
              alpha: AccueilUiTokens.blocMedaillonBorderVeil,
            ),
          ),
        ),
        child: Icon(
          module.icon,
          size: AccueilUiTokens.blocMedaillonIconSize,
          color: module.tone.accent,
        ),
      ),
    );
  }
}

/// Disque de lumière très faible ancré hors du coin haut droit, sous le
/// contenu — il donne du relief à l'aplat sans rien signifier.
class AccueilModuleBlocHalo extends StatelessWidget {
  const AccueilModuleBlocHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AccueilUiTokens.blocHaloOffset,
      right: AccueilUiTokens.blocHaloOffset,
      width: AccueilUiTokens.blocHaloSize,
      height: AccueilUiTokens.blocHaloSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accueilBlocInkMain.withValues(
            alpha: AccueilUiTokens.blocHaloVeil,
          ),
        ),
      ),
    );
  }
}

/// Anneau de focus clavier : 2 dp d'or, à 2 dp du bord (§07).
class AccueilModuleBlocFocusRing extends StatelessWidget {
  const AccueilModuleBlocFocusRing({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(AccueilUiTokens.blocFocusRingGap),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AccueilUiTokens.blocRadius - AccueilUiTokens.blocFocusRingGap,
            ),
            border: Border.all(
              color: AppColors.accueilBlocAccentOr,
              width: AccueilUiTokens.blocFocusRingWidth,
            ),
          ),
        ),
      ),
    );
  }
}
