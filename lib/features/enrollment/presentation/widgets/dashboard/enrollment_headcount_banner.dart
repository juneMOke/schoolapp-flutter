import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau d'effectif — **combien d'élèves**, la première des trois lectures.
///
/// Le seul chiffre de l'écran en 64 dp, et le seul qui **ne dépende pas de la
/// fenêtre** : il compte les dossiers terminés depuis l'ouverture des
/// inscriptions, quelle que soit la période affichée dessous.
///
/// ## La seule surface dégradée de l'écran
///
/// Tout le reste du tableau de bord est clair — cartes blanches ou teintées.
/// Ce bandeau prend le dégradé bleu de l'accueil, ce qui le situe dans la même
/// famille que le pavé du module. Il porte donc des **encres crème**, et c'est
/// la seule zone de l'écran où le contraste se lit à l'envers.
///
/// ⚠️ **Le chiffre est en sans-serif**, alors que le reste du produit met ses
/// grands nombres en Lora. C'est une règle explicite de la spec couleurs — « le
/// serif est réservé aux titres, jamais aux nombres » — et elle prime ici sur
/// l'habitude, parce qu'un effectif est une donnée, pas un titre.
///
/// ## Ce qu'il dit qu'il ne compte pas
///
/// La ligne fine sous le total n'est pas un ornement. Un effectif est le
/// chiffre qu'une école cite à l'extérieur ; s'il ne dit pas ce qu'il exclut,
/// il sera comparé à un registre qui, lui, compte autre chose. D'où la mention
/// explicite des demandes en ligne non validées.
///
/// ## Il reste à zéro plutôt que de disparaître
///
/// À l'état vide, le bandeau demeure avec son 0 : c'est un repère de lecture.
/// Retirer le seul chiffre stable de l'écran au moment où il n'y a rien
/// laisserait l'utilisateur sans point d'ancrage.
class EnrollmentHeadcountBanner extends StatelessWidget {
  /// L'effectif, hors fenêtre. Son total n'est **jamais** recalculé depuis les
  /// cartes ni depuis les barres.
  final GenderDistribution headcount;

  final String? schoolYear;

  const EnrollmentHeadcountBanner({
    super.key,
    required this.headcount,
    this.schoolYear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = headcount.total;

    return Semantics(
      container: true,
      label:
          '${l10n.enrollmentDashboardHeadcountOvertitle}. '
          '${l10n.enrollmentDashboardHeadcountA11yLabel(total)}. '
          '${l10n.enrollmentDashboardHeadcountExclusion}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: AppDimensions.enrollmentDashboardBannerGap,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // 105° : la lumière file vers la droite en descendant très
            // légèrement, comme le bandeau de l'accueil. L'arrêt est à 72 % et
            // non 78 % : ce bandeau est moins haut, la bascule doit arriver
            // plus tôt pour rester visible.
            gradient: const LinearGradient(
              begin: Alignment(-1, -0.26),
              end: Alignment(1, 0.26),
              colors: [
                AppColors.bleuProfond,
                AppColors.bleuArdoise,
                AppColors.bleuArdoiseLight,
              ],
              stops: [0, 0.72, 1],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.enrollmentDashboardBannerPaddingV,
                  horizontal: AppDimensions.enrollmentDashboardBannerPaddingH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Overtitle(
                      label: l10n.enrollmentDashboardHeadcountOvertitle,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    _Total(value: total),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.enrollmentDashboardHeadcountCaption(
                        total,
                        schoolYear ?? '',
                      ),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.insInkUnit,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      l10n.enrollmentDashboardHeadcountExclusion,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.insInkMeta,
                      ),
                    ),
                  ],
                ),
              ),
              const _GoldFilet(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le sur-titre, en or sur l'extrémité **sombre** du dégradé.
///
/// L'or ne tient que 3,4:1 sur l'extrémité claire ; il est ici à 6,3:1 parce
/// qu'il est ancré à gauche. Ne pas le centrer ni le pousser à droite.
class _Overtitle extends StatelessWidget {
  final String label;

  const _Overtitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.groups_rounded,
          size: AppDimensions.enrollmentDashboardBannerIconSize,
          color: AppColors.orDoux,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.badge.copyWith(
              color: AppColors.orDoux,
              letterSpacing:
                  AppDimensions.enrollmentDashboardOvertitleLetterSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le total, en **sans-serif** et en chiffres tabulaires.
///
/// Tabulaires pour que le chiffre ne « danse » pas d'une fenêtre à l'autre :
/// à cette taille, un 1 plus étroit qu'un 8 décale visiblement tout le nombre.
class _Total extends StatelessWidget {
  final int value;

  const _Total({required this.value});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        EnrollmentDashboardFormat.count(value),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: AppDimensions.enrollmentDashboardHeadcountFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -1,
          color: AppColors.insInkMain,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Filet d'or en tête, effacé vers la droite — la signature discrète que
/// partagent le bandeau d'accueil et celui-ci.
class _GoldFilet extends StatelessWidget {
  const _GoldFilet();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: AppDimensions.insBannerFiletHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orDoux, Color(0x00D9A24E)],
            stops: [0, AppDimensions.insSectionFiletFadeStop],
          ),
        ),
      ),
    );
  }
}
