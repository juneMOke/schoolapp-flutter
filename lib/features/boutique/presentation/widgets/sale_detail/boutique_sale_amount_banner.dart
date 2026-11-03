import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le montant, en Bleu Profond texturé — le même bandeau que le total du panier
/// et que la confirmation : c'est le même chiffre, d'un écran à l'autre.
class BoutiqueSaleAmountBanner extends StatelessWidget {
  final SaleDetail detail;

  const BoutiqueSaleAmountBanner({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brLg,
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
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.boutiqueTotalLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.orDoux,
                          letterSpacing: AppTypography.eyebrowLetterSpacing,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        // Un total par devise, joints par « · » : le bandeau
                        // est une ligne, et deux unités ne s'y additionnent pas.
                        detail.sale.lines.totals.entries
                            .map(MoneyFormat.format)
                            .join(' · '),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS / 2),
                      Text(
                        l10n.boutiqueHistoryArticleCount(
                          detail.sale.articleCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.storefront_outlined,
                  size: AppDimensions.boutiqueSaleBannerIconSize,
                  color: AppColors.textOnDark.withValues(alpha: 0.18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
