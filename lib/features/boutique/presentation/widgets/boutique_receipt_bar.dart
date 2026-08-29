import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui remplace le pied du panier une fois la vente encaissée.
///
/// **Le panier reste intact derrière**, et c'est délibéré : il permet de
/// réimprimer sans recomposer, et évite qu'un doigt malheureux efface la vente
/// qu'on est en train de remettre. Seul « Nouvelle vente » le vide.
///
/// Le sous-titre dit **lequel des deux documents** le porteur tient : un ticket
/// provisoire et un reçu scellé se ressemblent au comptoir, et c'est le seul
/// endroit où l'écran peut lever le doute.
class BoutiqueReceiptBar extends StatelessWidget {
  final RecordedSale sale;
  final VoidCallback onPrint;
  final VoidCallback onNewSale;

  /// Vrai pendant l'impression — le bouton se neutralise plutôt que de laisser
  /// empiler deux envois vers la même imprimante.
  final bool isPrinting;

  const BoutiqueReceiptBar({
    super.key,
    required this.sale,
    required this.onPrint,
    required this.onNewSale,
    this.isPrinting = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = BoutiqueMoneyFormat.exact(
      sale.sale.totalInCents,
      sale.sale.currency,
    );
    final receiptNumber = sale.sale.receiptNumber;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.vertSavane.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.vertSavane.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 22,
                color: AppColors.vertSavane,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.boutiqueReceiptBannerTitle(total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // Le numéro définitif dès qu'il existe ; sinon la mention
                      // provisoire, qui annonce ce qui va se passer plutôt que
                      // de constater un manque.
                      receiptNumber == null
                          ? l10n.boutiqueReceiptBannerProvisional(
                              ProvisionalSaleReference.of(sale.id),
                            )
                          : l10n.boutiqueReceiptBannerSealed(receiptNumber),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPrinting ? null : onPrint,
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(l10n.boutiqueReceiptPrint),
                  style: OutlinedButton.styleFrom(
                    // ⚠️ Sans `minimumSize`, un bouton inline hérite du thème
                    // plein-largeur et lève en contrainte infinie.
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNewSale,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.boutiqueReceiptNewSale),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.terreCuite,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
