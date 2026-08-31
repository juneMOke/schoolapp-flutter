import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_history_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_sale_detail_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_history_filter.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_history_sale_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// L'historique des ventes du guichet — **lu en local, exclusivement**.
///
/// Une caisse se consulte le jour où le réseau manque : demander au serveur ce
/// que la tablette a déjà écrit ferait dépendre l'historique du réseau, et le
/// guichet ne pourrait plus vérifier ce qu'il vient d'encaisser. C'est aussi ce
/// qui rend les ventes **en attente** visibles ici — le serveur, lui, ne les
/// connaît pas encore.
///
/// Le gate du contexte académique est ici comme sur la caisse : l'historique se
/// lit par exercice, et sans année courante il n'y a pas de périmètre.
class BoutiqueHistoryPage extends StatelessWidget {
  const BoutiqueHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<BoutiqueHistoryBloc>(
    create: (_) => getIt<BoutiqueHistoryBloc>(),
    child: const _HistoryGate(),
  );
}

class _HistoryGate extends StatefulWidget {
  const _HistoryGate();

  @override
  State<_HistoryGate> createState() => _HistoryGateState();
}

class _HistoryGateState extends State<_HistoryGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.context != curr.context,
      builder: (context, academicYearState) {
        if (academicYearState.status == AcademicYearContextLoadStatus.loading ||
            academicYearState.status == AcademicYearContextLoadStatus.initial) {
          return const AppPageBackground(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (academicYearState.status != AcademicYearContextLoadStatus.success) {
          return AppPageBackground(
            child: BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            ),
          );
        }

        return _HistoryView(
          academicYearId: academicYearState.context?.academicYear.id ?? '',
          // Les libellés de niveaux servent au TICKET : une ligne walk-in porte
          // un niveau déclaré, et l'imprimer par son identifiant ne dirait rien
          // à personne. Résolus ici, où le contexte est déjà lu.
          levelLabels: {
            for (final bundle
                in academicYearState.context?.schoolLevelGroups ??
                    const <SchoolLevelGroupBundle>[])
              for (final level in bundle.levels) level.id: level.name,
          },
        );
      },
    );
  }
}

class _HistoryView extends StatefulWidget {
  final String academicYearId;
  final Map<String, String> levelLabels;

  const _HistoryView({required this.academicYearId, required this.levelLabels});

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BoutiqueHistoryBloc>().add(
        BoutiqueHistoryRequested(widget.academicYearId),
      );
    });
  }

  /// Ouvre la fiche d'une vente, puis **relit la liste** au retour : la fiche
  /// peut avoir noté une impression, et la période affichée doit rester à jour
  /// après un aller-retour.
  Future<void> _openSale(BuildContext context, String saleId) async {
    final bloc = context.read<BoutiqueHistoryBloc>();
    await BoutiqueSaleDetailPage.push(
      context,
      saleId: saleId,
      levelLabels: widget.levelLabels,
    );
    // La fiche a pu rester ouverte pendant que l'écran disparaissait — session
    // expirée, retour à l'accueil. Poster sur un bloc fermé lèverait pour un
    // rafraîchissement dont plus personne n'a besoin.
    if (!mounted) return;
    bloc.add(BoutiqueHistoryRequested(widget.academicYearId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BoutiqueHistoryBloc, BoutiqueHistoryState>(
      builder: (context, state) {
        final bloc = context.read<BoutiqueHistoryBloc>();

        return AppPageBackground(
          appBar: BoutiqueTopBar(
            eyebrow: l10n.boutiqueHistoryEyebrow,
            title: l10n.boutiqueHistoryTitle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoutiqueHistoryFilter(
                selected: state.period,
                // Inerte pendant la lecture : changer de fenêtre sous une
                // requête en vol laisserait arriver la réponse de la précédente
                // par-dessus.
                enabled: state.status != HistoryStatus.loading,
                onChanged: (period) => bloc.add(
                  BoutiqueHistoryPeriodChanged(
                    academicYearId: widget.academicYearId,
                    period: period,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _Body(
                state: state,
                onRetry: () =>
                    bloc.add(BoutiqueHistoryRequested(widget.academicYearId)),
                onOpenSale: (sale) => _openSale(context, sale.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final BoutiqueHistoryState state;
  final VoidCallback onRetry;
  final void Function(SaleHistoryEntry sale) onOpenSale;

  const _Body({
    required this.state,
    required this.onRetry,
    required this.onOpenSale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == HistoryStatus.loading ||
        state.status == HistoryStatus.initial) {
      return EteeloListSkeleton(
        rowCount: 4,
        pillCount: 1,
        semanticsLabel: l10n.boutiqueHistoryTitle,
      );
    }

    if (state.status == HistoryStatus.failure) {
      return BoutiqueResultsErrorState(
        failure: state.failure!,
        onRetry: onRetry,
        surface: BoutiqueErrorSurface.history,
      );
    }

    if (state.sales.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.boutiqueHistoryEmptyTitle,
        description: l10n.boutiqueHistoryEmptyMessage,
        medallionIcon: Icons.receipt_long_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodSummary(state: state),
        const SizedBox(height: AppDimensions.spacingM),
        // Une `Column` et non un `ListView` : le défilement est celui de la
        // page, et une vue défilante imbriquée lèverait sous une contrainte de
        // hauteur non bornée.
        for (final sale in state.sales) ...[
          BoutiqueHistorySaleTile(sale: sale, onTap: () => onOpenSale(sale)),
          const SizedBox(height: AppDimensions.spacingS),
        ],
      ],
    );
  }
}

/// Ce que la fenêtre pèse : le nombre de ventes, le total **par devise**, et ce
/// qui n'est pas encore parti.
class _PeriodSummary extends StatelessWidget {
  final BoutiqueHistoryState state;

  const _PeriodSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totals = state.totalsByCurrency;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.terreCuite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.terreCuite.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Le total NOMME la fenêtre qu'il additionne : « Total
                    // encaissé » seul se lirait comme la caisse entière.
                    Text(
                      '${l10n.boutiqueHistoryTotalLabel} · '
                      '${BoutiqueHistoryFilter.labelOf(state.period, l10n)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      l10n.boutiqueHistorySaleCount(state.sales.length),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Une ligne PAR devise : additionner des dollars et des francs
                  // donnerait un nombre qui ne veut rien dire, et un guichet le
                  // lirait comme un montant.
                  for (final amount in totals.entries)
                    Text(
                      MoneyFormat.format(amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.bleuProfond,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (state.pendingCount > 0) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Expanded(
                  child: Text(
                    l10n.boutiqueHistoryPendingNotice(state.pendingCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
