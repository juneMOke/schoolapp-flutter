import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_roster_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Qui sont-ils » : la liste nominative de l'effectif — qui, quel rôle,
/// depuis quand —, filtrable et exportable telle qu'affichée.
class HrRosterCard extends StatelessWidget {
  /// Les lignes filtrées et triées, dans l'ordre de l'écran (et du PDF).
  final List<StaffFileRow> rows;
  final HrRosterQuery query;
  final HrStaffStats stats;
  final String today;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<HrCategoryKey?> onCategoryChanged;
  final ValueChanged<HrRosterSort> onSortChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<StaffFileRow> onOpen;
  final VoidCallback onExportPdf;

  const HrRosterCard({
    super.key,
    required this.rows,
    required this.query,
    required this.stats,
    required this.today,
    required this.onTextChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onOpen,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = HrPersonnelLabels.scope(l10n, query);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hrRosterTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.hrJoin(l10n.hrAgentsCount(rows.length), scope),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              EteeloButton.secondary(
                label: l10n.hrRosterPdf,
                icon: Icons.picture_as_pdf_outlined,
                tooltip: l10n.hrRosterPdfTooltip,
                onPressed: rows.isEmpty ? null : onExportPdf,
                fullWidth: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
              SizedBox(
                width: AppDimensions.hrRosterSortWidth,
                child: EteeloSelectInput<HrRosterSort>(
                  label: l10n.hrSortLabel,
                  value: query.sort == HrRosterSort.nameDescending
                      ? HrRosterSort.name
                      : query.sort,
                  onChanged: (sort) {
                    if (sort != null) onSortChanged(sort);
                  },
                  items: [
                    for (final sort in const [
                      HrRosterSort.name,
                      HrRosterSort.oldest,
                      HrRosterSort.newest,
                    ])
                      EteeloSelectItem(
                        value: sort,
                        label: HrPersonnelLabels.sort(l10n, sort),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
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
            )
          else
            for (final row in rows)
              HrRosterRow(
                key: ValueKey(row.member.id),
                row: row,
                today: today,
                onOpen: () => onOpen(row),
              ),
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

  /// L'effectif de [key] ; zéro pour une catégorie vide. La catégorie du
  /// filtre reste offerte même vidée (dernier agent modifié entre-temps) :
  /// sans elle, le sélecteur n'aurait plus d'option pour sa propre valeur.
  int _count(HrCategoryKey key) =>
      stats.categories.where((c) => c.key == key).firstOrNull?.count ?? 0;

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
        for (final key in HrCategoryKey.values)
          if (_count(key) > 0 || key == value)
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
