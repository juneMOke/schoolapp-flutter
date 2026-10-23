import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_tones.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_sales_filters.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_sales_report_button.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_sales_row.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Ventes de la période » — toutes les ventes de la fenêtre, **lues au
/// serveur**, 10 par page, filtrées par type d'article ou par classe, et leur
/// rapport PDF.
///
/// Le tableau des reçus de la caisse Finances : bandeau ocre, zébrure, cadre,
/// cartes sur téléphone. Toucher une ligne rouvre la fiche locale de la vente.
class BoutiqueSalesCard extends StatelessWidget {
  /// Les ventes de la fenêtre que le serveur ne connaît pas encore : absentes
  /// de la liste et du PDF, l'écran le dit.
  final int provisionalCount;
  final void Function(BoutiqueSaleRow sale) onOpenSale;
  final VoidCallback onNewSale;

  const BoutiqueSalesCard({
    super.key,
    required this.provisionalCount,
    required this.onOpenSale,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const tone = BoutiqueDashboardTones.ventes;
    return BlocBuilder<BoutiqueSalesCubit, BoutiqueSalesState>(
      builder: (context, state) {
        final cubit = context.read<BoutiqueSalesCubit>();
        final page = state.page;
        final query = state.query;
        return EteeloStatsCard(
          title: l10n.boutiqueSalesTitle,
          subtitle: page == null
              ? null
              : l10n.boutiqueSalesSubtitle(page.totalElements),
          icon: Icons.receipt_long_outlined,
          tone: tone,
          toneStrength: BoutiqueDashboardTones.sectionStrength(tone),
          actions: [
            // Le PDF s'offre dès que la liste a des ventes, et reste en place
            // pendant qu'une autre page charge : il ne dépend pas de la page.
            if (query != null && page != null && page.totalElements > 0)
              BoutiqueSalesReportButton(query: query),
            EteeloButton.ghost(
              label: l10n.boutiqueLatestSalesNewSale,
              icon: Icons.arrow_forward_rounded,
              onPressed: onNewSale,
              fullWidth: false,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoutiqueSalesFilters(state: state, cubit: cubit),
              if (provisionalCount > 0) ...[
                const SizedBox(height: AppDimensions.spacingS),
                EteeloNotice.tinted(
                  icon: Icons.cloud_off_outlined,
                  ink: AppColors.warningInk,
                  background: AppColors.boutiqueUnresolvedSurface,
                  border: AppColors.warning,
                  message: l10n.boutiqueSalesProvisionalNote(provisionalCount),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingM),
              _Body(state: state, cubit: cubit, onOpenSale: onOpenSale),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final BoutiqueSalesState state;
  final BoutiqueSalesCubit cubit;
  final void Function(BoutiqueSaleRow sale) onOpenSale;

  const _Body({
    required this.state,
    required this.cubit,
    required this.onOpenSale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = state.page;
    final loading = state.status == SalesStatus.loading;

    if (state.status == SalesStatus.failure) {
      return BoutiqueResultsErrorState(
        failure: state.failure!,
        onRetry: cubit.retry,
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        surface: BoutiqueErrorSurface.dashboard,
      );
    }
    // Première lecture, ou autre question : le cubit a retiré l'ancienne page.
    if (page == null) {
      return EteeloListSkeleton(
        rowCount: 3,
        semanticsLabel: l10n.boutiqueSalesTitle,
      );
    }
    if (page.items.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.boutiqueSalesEmptyTitle,
        description: state.hasFilter
            ? l10n.boutiqueSalesEmptyFiltered(_filterLabel(l10n))
            : l10n.boutiqueSalesEmptyNone,
        medallionIcon: Icons.receipt_long_outlined,
        fullWidthCard: true,
        primaryAction: state.hasFilter
            ? EteeloButton.secondary(
                label: l10n.boutiqueSalesReset,
                onPressed: cubit.resetFilter,
                fullWidth: false,
              )
            : null,
      );
    }

    return DataTableView(
      rows: [
        for (final sale in page.items)
          BoutiqueSalesRow.of(sale, l10n, onOpen: onOpenSale),
      ],
      config: DataTableViewConfig(
        tone: BoutiqueDashboardTones.tableOf(BoutiqueDashboardTones.ventes),
        semanticsLabel: l10n.boutiqueSalesTitle,
        density: DataTableDensity.compact,
        phoneLayout: DataTablePhoneLayout.cards,
        // Sur téléphone, la carte se titre par les élèves.
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
          DataTableColumnDef(label: l10n.boutiqueSalesColumnStudents, flex: 20),
          DataTableColumnDef(
            label: l10n.boutiqueLatestSalesColumnAmount,
            flex: 12,
          ),
        ],
        footer: DataTableFooterConfig(
          label: l10n.boutiqueSalesCount(page.totalElements),
          total: page.totalElements,
          unit: l10n.boutiqueSalesUnit,
          pagination: page.totalPages <= 1
              ? null
              : DataTablePaginationConfig(
                  // Le serveur compte les pages à partir de 0, la barre du
                  // socle à partir de 1.
                  currentPage: page.page + 1,
                  totalPages: page.totalPages,
                  pageSize: SalesQuery.pageSize,
                  isLoading: loading,
                  onPrevious: () => cubit.pageChanged(page.page - 1),
                  onNext: () => cubit.pageChanged(page.page + 1),
                ),
        ),
      ),
    );
  }

  String _filterLabel(AppLocalizations l10n) => switch (state.mode) {
    SalesFilterMode.family => BoutiqueFamilyStyle.labelOf(state.family, l10n),
    SalesFilterMode.classroom => state.classLabel ?? '',
  };
}
