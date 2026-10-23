import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/tables/data_table_density.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_view.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_sale_time.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les six derniers reçus de la période, **lus en local** — provisoires
/// compris. Toucher une ligne rouvre la même fiche que la caisse : ticket,
/// reçu scellé, réimpression.
///
/// Le tableau des reçus de la caisse Finances, à l'identique : bandeau ocre,
/// zébrure, colonnes Date · Reçu · Payeur · Montant, l'œil en bout de ligne —
/// et des cartes sur téléphone.
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
    const tone = BoutiqueDashboardTones.ventes;

    return EteeloStatsCard(
      title: l10n.boutiqueLatestSalesTitle,
      subtitle: l10n.boutiqueLatestSalesSubtitle,
      icon: Icons.receipt_long_outlined,
      tone: tone,
      toneStrength: BoutiqueDashboardTones.sectionStrength(tone),
      actions: [
        EteeloButton.ghost(
          label: l10n.boutiqueLatestSalesNewSale,
          icon: Icons.arrow_forward_rounded,
          onPressed: onNewSale,
          fullWidth: false,
        ),
      ],
      child: sales == null
          ? Text(
              l10n.boutiqueLatestSalesError,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            )
          : DataTableView(
              rows: [for (final sale in sales) _rowOf(sale, l10n)],
              config: DataTableViewConfig(
                tone: BoutiqueDashboardTones.tableOf(tone),
                emptyLabel: l10n.boutiqueLatestSalesEmpty,
                semanticsLabel: l10n.boutiqueLatestSalesTitle,
                density: DataTableDensity.compact,
                phoneLayout: DataTablePhoneLayout.cards,
                cardTitleColumn: 2,
                columns: [
                  DataTableColumnDef(
                    label: l10n.boutiqueLatestSalesColumnDate,
                    flex: 10,
                  ),
                  DataTableColumnDef(
                    label: l10n.boutiqueLatestSalesColumnReceipt,
                    flex: 11,
                  ),
                  DataTableColumnDef(
                    label: l10n.boutiqueLatestSalesColumnPayer,
                    flex: 20,
                  ),
                  DataTableColumnDef(
                    label: l10n.boutiqueLatestSalesColumnAmount,
                    flex: 12,
                  ),
                ],
              ),
            ),
    );
  }

  DataTableRowSpec _rowOf(SaleHistoryEntry sale, AppLocalizations l10n) {
    final payer = sale.payerName.trim().isEmpty
        ? l10n.boutiqueHistoryPayerUnknown
        : sale.payerName;
    void open() => onOpenSale(sale);

    return DataTableRowSpec(
      id: sale.id,
      displayName: payer,
      // La ligne EST le geste : au guichet, un parent qui revient avec son
      // ticket attend qu'on retrouve sa vente d'un doigt. L'œil le redit pour
      // qui cherche l'action en bout de ligne, comme à la caisse.
      onTap: open,
      trailing: DataTableTrailingSpec(
        type: DataTableTrailingType.eye,
        tooltip: l10n.boutiqueLatestSalesOpen,
        onTap: open,
      ),
      cells: [
        DataTableCellSpec(
          text: BoutiqueSaleTime.of(sale.soldAt, DateTime.now()),
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          // Le numéro scellé dès qu'il existe ; sinon la référence provisoire,
          // qui dit ce qui manque plutôt que de laisser un blanc.
          text: sale.receiptNumber ?? ProvisionalSaleReference.of(sale.id),
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: payer,
          variant: DataTableCellTextVariant.strong,
          secondaryText: l10n.boutiqueHistoryArticleCount(sale.articleCount),
        ),
        DataTableCellSpec(
          // Exact, jamais arrondi : c'est de l'argent encaissé, et un guichet
          // qui rapproche sa caisse compte au centime. Deux devises côte à côte.
          text: sale.amounts.entries.map(MoneyFormat.format).join(' · '),
          variant: DataTableCellTextVariant.strong,
          // L'attente se DIT, elle ne se déduit pas d'un numéro absent : une
          // vente partie mais sans reçu encore réclamé n'est pas en attente.
          secondaryText: sale.isPending
              ? l10n.boutiqueHistoryPendingBadge
              : null,
          secondaryColor: sale.isPending
              ? DashboardTones.encreLisible(AppColors.warning)
              : null,
        ),
      ],
    );
  }
}
