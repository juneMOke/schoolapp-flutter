import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// En-tête sombre partagé par les modales de l'application : même bandeau
/// Bleu Profond texturé Kuba que les AppBar de pages, pour qu'une popin
/// n'arrive pas comme un objet étranger au reste de l'écran.

/// En-tête sombre : sur-titre or-doux (MAJUSCULES) + titre blanc + pastille
/// optionnelle (statut/solde) + croix de fermeture. Fond Bleu Profond texturé
/// Kuba, comme l'AppBar des pages de l'application.
class EteeloDialogDarkHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? trailing;
  final VoidCallback onClose;

  const EteeloDialogDarkHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              AppDimensions.spacingM,
              AppDimensions.spacingS,
              AppDimensions.spacingM,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.orDoux,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.totalAmountLora.copyWith(
                          fontSize: 24,
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  trailing!,
                ],
                const SizedBox(width: AppDimensions.spacingXS),
                IconButton(
                  onPressed: onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.textOnDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Liseré or-doux (dégradé horizontal, opacité .55) séparant l'en-tête.
class EteeloDialogGoldDivider extends StatelessWidget {
  const EteeloDialogGoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orDoux.withValues(alpha: 0),
            AppColors.orDoux.withValues(alpha: 0.55),
            AppColors.orDoux.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
