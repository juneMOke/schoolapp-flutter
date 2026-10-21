import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les six derniers reçus de la période, **lus en local** — provisoires
/// compris. Toucher une ligne rouvre la même fiche que la caisse : ticket,
/// reçu scellé, réimpression.
class BoutiqueLatestSalesCard extends StatelessWidget {
  /// `null` : la lecture locale a échoué.
  final List<SaleHistoryEntry>? sales;
  final ValueChanged<SaleHistoryEntry> onOpenSale;
  final VoidCallback onNewSale;

  const BoutiqueLatestSalesCard({
    super.key,
    required this.sales,
    required this.onOpenSale,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sales = this.sales;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );

    return EteeloStatsCard(
      title: l10n.boutiqueLatestSalesTitle,
      subtitle: l10n.boutiqueLatestSalesSubtitle,
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.terreCuite,
      actions: [
        EteeloButton.ghost(
          label: l10n.boutiqueLatestSalesNewSale,
          icon: Icons.arrow_forward_rounded,
          onPressed: onNewSale,
          fullWidth: false,
        ),
      ],
      child: switch (sales) {
        null => Text(l10n.boutiqueLatestSalesError, style: muted),
        [] => Text(l10n.boutiqueLatestSalesEmpty, style: muted),
        _ => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final sale in sales) ...[
              BoutiqueSaleTile(sale: sale, onTap: () => onOpenSale(sale)),
              const SizedBox(height: AppDimensions.spacingS),
            ],
          ],
        ),
      },
    );
  }
}
