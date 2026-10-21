import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_beneficiaries_filters.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_beneficiary_tile.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Élèves concernés » — la question des surveillants et titulaires : « qui a
/// déjà son polo ? »
///
/// Son propre état : un filtre recharge la carte, jamais l'écran.
class BoutiqueBeneficiariesCard extends StatelessWidget {
  const BoutiqueBeneficiariesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BoutiqueBeneficiariesCubit, BoutiqueBeneficiariesState>(
      builder: (context, state) {
        final cubit = context.read<BoutiqueBeneficiariesCubit>();
        final count = state.page?.totalElements ?? 0;
        final article = state.articleLabel;
        return EteeloStatsCard(
          title: l10n.boutiqueBeneficiariesTitle,
          subtitle: article == null
              ? l10n.boutiqueBeneficiariesSubtitleAll(count)
              : l10n.boutiqueBeneficiariesSubtitleArticle(article, count),
          icon: Icons.groups_outlined,
          iconColor: AppColors.bleuArdoise,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoutiqueBeneficiariesFilters(state: state, cubit: cubit),
              const SizedBox(height: AppDimensions.spacingM),
              _Body(state: state, cubit: cubit),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final BoutiqueBeneficiariesState state;
  final BoutiqueBeneficiariesCubit cubit;

  const _Body({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = state.page;

    if (state.status == BeneficiariesStatus.loading ||
        state.status == BeneficiariesStatus.initial) {
      // Trois lignes, dans la carte seulement.
      return EteeloListSkeleton(
        rowCount: 3,
        semanticsLabel: l10n.boutiqueBeneficiariesTitle,
      );
    }
    if (state.status == BeneficiariesStatus.failure || page == null) {
      return BoutiqueResultsErrorState(
        failure: state.failure!,
        onRetry: cubit.retry,
        surface: BoutiqueErrorSurface.dashboard,
      );
    }

    final note = _Notes(
      walkIns: page.walkInLineCount,
      partialOf: page.partial ? page.items.length : null,
    );
    if (page.items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloEmptyResult(
            label: l10n.boutiqueBeneficiariesEmptyTitle,
            description: state.hasFilters
                ? l10n.boutiqueBeneficiariesEmptyFiltered(_filtersOf(state))
                : l10n.boutiqueBeneficiariesEmptyNone,
            medallionIcon: Icons.person_search_outlined,
            fullWidthCard: true,
            primaryAction: state.hasFilters
                ? EteeloButton.secondary(
                    label: l10n.boutiqueBeneficiariesReset,
                    onPressed: cubit.resetFilters,
                    fullWidth: false,
                  )
                : null,
          ),
          note,
        ],
      );
    }

    final shown = state.expanded
        ? page.items
        : page.items.take(BoutiqueBeneficiariesState.collapsedCount).toList();
    final canExpand =
        page.items.length > BoutiqueBeneficiariesState.collapsedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final student in shown) BoutiqueBeneficiaryTile(student: student),
        if (canExpand || (state.expanded && page.hasMore))
          Wrap(
            spacing: AppDimensions.spacingS,
            children: [
              if (canExpand)
                EteeloButton.ghost(
                  label: state.expanded
                      ? l10n.boutiqueBeneficiariesCollapse
                      : l10n.boutiqueBeneficiariesShowAll(page.totalElements),
                  onPressed: cubit.toggleExpanded,
                  fullWidth: false,
                ),
              if (state.expanded && page.hasMore)
                EteeloButton.ghost(
                  label: l10n.boutiqueBeneficiariesLoadMore,
                  isLoading: state.loadingMore,
                  onPressed: cubit.loadMore,
                  fullWidth: false,
                ),
            ],
          ),
        note,
      ],
    );
  }

  /// « « Polo Lacoste » · 6e A · « kab » » — l'état vide NOMME ce qui filtre.
  static String _filtersOf(BoutiqueBeneficiariesState state) => [
    if (state.articleLabel != null) '« ${state.articleLabel} »',
    if (state.classLabel != null) state.classLabel!,
    if (state.search.trim().isNotEmpty) '« ${state.search.trim()} »',
  ].join(' · ');
}

/// Les mentions sous la liste : achats sans élève, recherche hors ligne
/// partielle.
class _Notes extends StatelessWidget {
  final int walkIns;
  final int? partialOf;

  const _Notes({required this.walkIns, this.partialOf});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.textMutedAa,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (partialOf != null)
            Text(l10n.boutiqueBeneficiariesPartial(partialOf!), style: style),
          if (walkIns > 0)
            Text(l10n.boutiqueBeneficiariesWalkIn(walkIns), style: style),
        ],
      ),
    );
  }
}
