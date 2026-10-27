import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_sort_select.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de filtres du Fichier : recherche, catégorie, ordre et bascule
/// cartes/liste, puis la légende des pastilles. Ni puce de contrat ni « dossier
/// incomplet » : ce sont des statistiques, et elles vivent au tableau de bord.
class HrFileFiltersCard extends StatelessWidget {
  final HrRosterQuery query;
  final CollectionViewMode viewMode;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<HrCategoryKey?> onCategoryChanged;
  final ValueChanged<HrRosterSort> onSortChanged;
  final ValueChanged<CollectionViewMode> onViewModeChanged;

  const HrFileFiltersCard({
    super.key,
    required this.query,
    required this.viewMode,
    required this.onTextChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffSearchToolbar(
            text: query.text,
            label: l10n.staffSearchLabel,
            placeholder: l10n.staffSearchPlaceholder,
            onTextChanged: onTextChanged,
            category: query.category?.category,
            onCategoryChanged: (category) => onCategoryChanged(
              category == null ? null : HrCategoryKey.of(category),
            ),
            viewMode: viewMode,
            onViewModeChanged: onViewModeChanged,
            trailingFilters: [
              HrSortSelect(value: query.sort, onChanged: onSortChanged),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.lg,
            children: [
              RecordSyncPill(state: RecordSyncState.pending),
              RecordSyncPill(state: RecordSyncState.synced),
            ],
          ),
        ],
      ),
    );
  }
}
