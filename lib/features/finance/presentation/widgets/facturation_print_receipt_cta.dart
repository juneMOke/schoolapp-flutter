import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Bouton CTA « Imprimer le reçu » — pleine largeur avec gradient d'accent.
///
/// Conçu pour apparaître en bas des sections de détail de paiement.
/// Délègue entièrement l'action au parent via [onPressed].
class FacturationPrintReceiptCta extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final String subtitle;

  const FacturationPrintReceiptCta({
    super.key,
    required this.onPressed,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(
              AppDimensions.sectionCardRadius,
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingM,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.spacingXL + AppDimensions.spacingM,
                  height: AppDimensions.spacingXL + AppDimensions.spacingM,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                  ),
                  child: const Icon(
                    Icons.print_outlined,
                    size: AppDimensions.detailHeaderIconSize,
                    color: AppColors.bleuArdoise,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textMuted,
                  size: AppDimensions.detailHeaderIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
