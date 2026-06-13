import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte de felicitation affichee a la place du detail quand il n'y a aucune
/// absence sur la periode (assiduite parfaite). La synthese reste au-dessus.
class PresencePerfectCard extends StatelessWidget {
  const PresencePerfectCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final medallion = Container(
      width: AppDimensions.presencePerfectMedallionSize,
      height: AppDimensions.presencePerfectMedallionSize,
      decoration: BoxDecoration(
        color: AppColors.vertSavane.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline_rounded,
        size: AppDimensions.presencePerfectIconSize,
        color: AppColors.vertSavane,
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // « etPopIn » : desactive en mouvement reduit (etat final visible).
          if (reduceMotion)
            medallion
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: AppMotion.medium,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: medallion,
            ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.presencePerfectTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.presencePerfectMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
