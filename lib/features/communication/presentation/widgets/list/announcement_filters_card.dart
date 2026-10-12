import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_labels.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_visuals.dart';
import 'package:school_app_flutter/features/communication/presentation/projections/announcement_list_view.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/common/communication_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de filtres : recherche, statuts, catégories. Sélection multiple ;
/// aucune pastille cochée dans un groupe = aucun filtre sur ce critère.
class AnnouncementFiltersCard extends StatelessWidget {
  final AnnouncementFilters filters;
  final AnnouncementListView view;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AnnouncementStatus> onToggleStatus;
  final ValueChanged<AnnouncementCategory> onToggleCategory;
  final VoidCallback onClear;

  const AnnouncementFiltersCard({
    super.key,
    required this.filters,
    required this.view,
    required this.onQueryChanged,
    required this.onToggleStatus,
    required this.onToggleCategory,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CommunicationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloSearchToolbar(
            text: filters.query,
            label: l10n.communicationSearchLabel,
            placeholder: l10n.communicationSearchPlaceholder,
            onTextChanged: onQueryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _Group(
            label: l10n.communicationFilterStatus,
            chips: [
              for (final status in AnnouncementListView.groupOrder)
                // Un échec ne s'offre en filtre que s'il y en a : la pastille
                // dirait sinon un problème qui n'existe pas.
                if (status != AnnouncementStatus.failed ||
                    (view.statusCounts[status] ?? 0) > 0 ||
                    filters.statuses.contains(status))
                  _statusChip(l10n, status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Group(
            label: l10n.communicationFilterCategory,
            chips: [
              for (final category in AnnouncementCategory.values)
                _categoryChip(l10n, category),
            ],
          ),
          if (filters.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.communicationFilterShown(view.shown, view.total),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                EteeloButton.ghost(
                  label: l10n.communicationFilterClear(filters.activeCount),
                  icon: Icons.close,
                  onPressed: onClear,
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(AppLocalizations l10n, AnnouncementStatus status) {
    final tone = statusTone(status);
    return EteeloFilterChip(
      label: l10n.statusGroupLabel(status),
      count: view.statusCounts[status] ?? 0,
      selected: filters.statuses.contains(status),
      color: tone.ink,
      soft: tone.soft,
      ink: tone.ink,
      onTap: () => onToggleStatus(status),
    );
  }

  Widget _categoryChip(AppLocalizations l10n, AnnouncementCategory category) {
    final tone = categoryTone(category);
    return EteeloFilterChip(
      label: l10n.categoryLabel(category),
      count: view.categoryCounts[category] ?? 0,
      selected: filters.categories.contains(category),
      color: tone.ink,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => onToggleCategory(category),
    );
  }
}

class _Group extends StatelessWidget {
  final String label;
  final List<Widget> chips;

  const _Group({required this.label, required this.chips});

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        ...chips,
      ],
    ),
  );
}
