import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une vente de l'historique.
///
/// Le montant est **exact**, jamais arrondi : c'est de l'argent encaissé, et un
/// guichet qui rapproche sa caisse compte au centime.
class BoutiqueHistorySaleTile extends StatelessWidget {
  final SaleHistoryEntry sale;

  /// Ouvre la fiche de la vente. La ligne EST le geste : au guichet, un chevron
  /// discret ne se vise pas, et un parent qui revient avec son ticket attend
  /// qu'on retrouve sa vente d'un doigt.
  final VoidCallback onTap;

  const BoutiqueHistorySaleTile({
    super.key,
    required this.sale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final payer = sale.payerName.trim().isEmpty
        ? l10n.boutiqueHistoryPayerUnknown
        : sale.payerName;

    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payer,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.bleuProfond,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.boutiqueHistorySaleTime(
                          _timeOf(sale.soldAt, DateTime.now()),
                          // Le numéro scellé dès qu'il existe ; sinon la référence
                          // provisoire, qui dit ce qui manque plutôt que de laisser
                          // un blanc.
                          sale.receiptNumber ??
                              ProvisionalSaleReference.of(sale.id),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.boutiqueHistoryArticleCount(sale.articleCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      BoutiqueMoneyFormat.exact(
                        sale.totalInCents,
                        sale.currency,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.bleuProfond,
                      ),
                    ),
                    // L'attente se DIT, elle ne se déduit pas d'un numéro absent : une
                    // vente partie mais sans reçu encore réclamé n'est pas en attente.
                    if (sale.isPending) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.boutiqueHistoryPendingBadge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// L'heure **locale** de la vente : `sold_at` est en UTC, et l'afficher tel
  /// quel décalerait chaque vente au guichet.
  ///
  /// La date n'apparaît que si la vente n'est pas d'aujourd'hui : sur la caisse
  /// du jour — la fenêtre par défaut — elle serait la même sur chaque ligne, et
  /// noierait l'heure, qui est ce qu'on cherche.
  ///
  /// Un horodatage illisible ne fait pas disparaître la vente : le montant et le
  /// payeur restent la raison d'être de la ligne.
  static String _timeOf(String soldAt, DateTime now) {
    final parsed = DateTime.tryParse(soldAt);
    if (parsed == null) return soldAt;
    final local = parsed.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    final time = '${two(local.hour)}:${two(local.minute)}';
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return isToday ? time : '${two(local.day)}/${two(local.month)} $time';
  }
}
