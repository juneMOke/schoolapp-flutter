import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_sort_select.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_roster_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_staff_list_report_button.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/states/hr_dashboard_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Qui sont-ils » : la liste nominative de l'effectif — qui, quel rôle,
/// depuis quand —, filtrée, triée et découpée par le serveur, et imprimable
/// telle qu'affichée : le PDF reprend la même question.
///
/// Le tableau de Boutique et des reçus de la caisse : carte de section
/// teintée, bandeau, zébrure, cadre, une carte par agent sur téléphone. Le
/// bleu ardoise des effectifs, comme « Élèves concernés » à la Boutique.
class HrRosterCard extends StatelessWidget {
  /// Un effectif : le ton partagé des tableaux de bord.
  static const Color tone = DashboardSense.attendu;

  final HrStaffMembersState members;
  final HrStaffStats stats;

  /// L'état de la fiche sur cette tablette, par agent.
  final RecordSyncState? Function(String id) syncOf;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<HrCategoryKey?> onCategoryChanged;
  final ValueChanged<HrRosterSort> onSortChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<HrStaffMemberRow> onOpen;

  /// [page] à partir de 0.
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRetry;

  const HrRosterCard({
    super.key,
    required this.members,
    required this.stats,
    required this.syncOf,
    required this.onTextChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onOpen,
    required this.onPageChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = members.query;
    final scope = HrPersonnelLabels.scope(l10n, query);
    final page = members.page;
    // Le PDF n'imprime que la liste à l'écran : pas pendant une lecture, ni
    // pendant la frappe d'une recherche qui n'est pas encore partie.
    final printable =
        page != null &&
            page.totalElements > 0 &&
            members.status == HrStaffMembersStatus.ready &&
            members.answered == members.query
        ? members.answered
        : null;
    return EteeloStatsCard(
      title: l10n.hrRosterTitle,
      subtitle: page == null
          ? scope
          : l10n.hrJoin(l10n.hrAgentsCount(page.totalElements), scope),
      icon: Icons.groups_outlined,
      tone: HrRosterCard.tone,
      toneStrength: DashboardTones.forceDe(HrRosterCard.tone),
      actions: [HrStaffListReportButton(query: printable)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloSearchToolbar(
            text: query.text,
            label: l10n.hrRosterSearchLabel,
            placeholder: l10n.hrRosterSearchPlaceholder,
            onTextChanged: onTextChanged,
            filters: [
              SizedBox(
                width: AppDimensions.staffCategoryWidth,
                child: _CategorySelect(
                  stats: stats,
                  value: query.category,
                  onChanged: onCategoryChanged,
                ),
              ),
              HrSortSelect(value: query.sort, onChanged: onSortChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ..._results(context, l10n, scope),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.hrRosterFooter,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
              const RecordSyncPill(state: RecordSyncState.synced),
              const RecordSyncPill(state: RecordSyncState.pending),
            ],
          ),
        ],
      ),
    );
  }
}

extension on HrRosterCard {
  List<Widget> _results(
    BuildContext context,
    AppLocalizations l10n,
    String scope,
  ) {
    final page = members.page;
    if (members.status == HrStaffMembersStatus.failure) {
      return [
        HrDashboardResultsErrorState(
          failure: members.failure,
          onRetry: onRetry,
        ),
      ];
    }
    if (page == null) {
      return [
        EteeloListSkeleton(rowCount: 5, semanticsLabel: l10n.hrRosterLoading),
      ];
    }
    if (page.items.isEmpty) {
      return [
        EteeloEmptyResult(
          label: l10n.hrRosterEmptyTitle,
          description: l10n.hrRosterEmptyMessage(scope),
          medallionIcon: Icons.search_rounded,
          fullWidthCard: true,
          primaryAction: EteeloButton.secondary(
            label: l10n.hrRosterShowAll,
            icon: Icons.close,
            onPressed: onClearFilters,
            fullWidth: false,
          ),
        ),
      ];
    }
    final withDossier = page.items.any((row) => row.dossier != null);
    return [
      DataTableView(
        rows: [
          for (final row in page.items)
            HrRosterRow.of(
              row,
              l10n,
              sync: syncOf(row.id),
              withDossier: withDossier,
              onOpen: () => onOpen(row),
            ),
        ],
        config: DataTableViewConfig(
          tone: ListingTones.tableTone(HrRosterCard.tone),
          semanticsLabel: l10n.hrRosterTitle,
          density: DataTableDensity.compact,
          phoneLayout: DataTablePhoneLayout.cards,
          columns: [
            DataTableColumnDef(label: l10n.hrRosterColumnAgent, flex: 24),
            DataTableColumnDef(label: l10n.hrRosterColumnCategory, flex: 12),
            DataTableColumnDef(label: l10n.hrRosterColumnContract, flex: 11),
            DataTableColumnDef(label: l10n.hrRosterColumnSeniority, flex: 12),
            if (withDossier)
              DataTableColumnDef(label: l10n.hrRosterColumnDossier, flex: 10),
          ],
          footer: DataTableFooterConfig(
            label: l10n.hrAgentsCount(page.totalElements),
            total: page.totalElements,
            unit: l10n.hrRosterUnit,
            pagination: page.totalPages <= 1
                ? null
                : DataTablePaginationConfig(
                    // Le serveur compte les pages à partir de 0, la barre du
                    // socle à partir de 1.
                    currentPage: page.page + 1,
                    totalPages: page.totalPages,
                    pageSize: AppConstants.hrStaffMembersPageSize,
                    isLoading: members.status == HrStaffMembersStatus.loading,
                    onPrevious: () => onPageChanged(page.page - 1),
                    onNext: () => onPageChanged(page.page + 1),
                  ),
          ),
        ),
      ),
    ];
  }
}

/// « Tous · 14 », puis chaque catégorie non vide avec son effectif.
class _CategorySelect extends StatelessWidget {
  final HrStaffStats stats;
  final HrCategoryKey? value;
  final ValueChanged<HrCategoryKey?> onChanged;

  const _CategorySelect({
    required this.stats,
    required this.value,
    required this.onChanged,
  });

  /// La catégorie du filtre reste offerte même vidée (dernier agent modifié
  /// entre-temps) : sans elle, le sélecteur n'aurait plus d'option pour sa
  /// propre valeur.
  int _count(HrCategoryKey key) => stats.countOf(key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloSelectInput<String>(
      label: l10n.hrCategoryFilterLabel,
      value: value?.name ?? '',
      onChanged: (name) => onChanged(
        HrCategoryKey.values.where((key) => key.name == name).firstOrNull,
      ),
      items: [
        EteeloSelectItem(
          value: '',
          label: l10n.hrCategoryAllCount(stats.headcount),
        ),
        // Jamais « non renseignée » : le serveur ne la connaît pas, et la
        // refuserait en 400.
        for (final key in HrCategoryKey.values)
          if (key != HrCategoryKey.unknown && (_count(key) > 0 || key == value))
            EteeloSelectItem(
              value: key.name,
              label: l10n.hrCategoryOptionCount(
                HrPersonnelLabels.category(l10n, key),
                _count(key),
              ),
            ),
      ],
    );
  }
}
