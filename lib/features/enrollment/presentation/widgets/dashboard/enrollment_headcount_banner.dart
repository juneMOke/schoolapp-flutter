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
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.enrollmentDashboardBannerPaddingV,
            horizontal: AppDimensions.enrollmentDashboardBannerPaddingH,
          ),
          decoration: BoxDecoration(
            color: AppColors.bleuArdoiseSoft,
            borderRadius: BorderRadius.circular(
              AppDimensions.sectionCardRadius,
            ),
            border: Border.all(color: AppColors.enrollmentStatsChartGrid),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Overtitle(label: l10n.enrollmentDashboardHeadcountOvertitle),
              const SizedBox(height: AppDimensions.spacingS),
              _Total(value: total),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                l10n.enrollmentDashboardHeadcountCaption(
                  total,
                  schoolYear ?? '',
                ),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.enrollmentDashboardHeadcountExclusion,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          color: AppColors.bleuArdoise,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.badge.copyWith(
              color: AppColors.bleuArdoise,
              letterSpacing:
                  AppDimensions.enrollmentDashboardOvertitleLetterSpacing,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le total, en serif et en chiffres tabulaires.
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
        style: AppTextStyles.totalAmountLora.copyWith(
          fontSize: AppDimensions.enrollmentDashboardHeadcountFontSize,
          fontWeight: FontWeight.w600,
          height: 1,
          color: AppColors.bleuArdoise,
        ),
      ),
    );
  }
}
