import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';

/// La carte de filtres : recherche, catégorie et affichage sur une ligne, puis
/// les puces de contrat et « Dossier incomplet ». Tous les filtres se
/// combinent.
class StaffFiltersCard extends StatelessWidget {
  final StaffFileQuery query;
  final StaffFileView view;
  final CollectionViewMode viewMode;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<StaffCategory?> onCategoryChanged;
  final ValueChanged<StaffContractFilter?> onContractToggled;
  final VoidCallback onIncompleteToggled;
  final ValueChanged<CollectionViewMode> onViewModeChanged;

  const StaffFiltersCard({
    super.key,
    required this.query,
    required this.view,
    required this.viewMode,
    required this.onTextChanged,
    required this.onCategoryChanged,
    required this.onContractToggled,
    required this.onIncompleteToggled,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSearchToolbar(
            text: query.text,
            label: l10n.staffSearchLabel,
            placeholder: l10n.staffSearchPlaceholder,
            onTextChanged: onTextChanged,
            category: query.category,
            onCategoryChanged: onCategoryChanged,
            viewMode: viewMode,
            onViewModeChanged: onViewModeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          _ContractChips(
            query: query,
            view: view,
            onContractToggled: onContractToggled,
            onIncompleteToggled: onIncompleteToggled,
          ),
        ],
      ),
    );
  }
}

class _ContractChips extends StatelessWidget {
  final StaffFileQuery query;
  final StaffFileView view;
  final ValueChanged<StaffContractFilter?> onContractToggled;
  final VoidCallback onIncompleteToggled;

  const _ContractChips({
    required this.query,
    required this.view,
    required this.onContractToggled,
    required this.onIncompleteToggled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        EteeloFilterChip(
          label: l10n.staffContractAll,
          count: view.all.length,
          selected: query.contract == null,
          color: AppColors.bleuArdoise,
          soft: AppColors.bleuArdoiseSoft,
          ink: AppColors.bleuArdoise,
          onTap: () => onContractToggled(null),
        ),
        for (final filter in StaffContractFilter.values)
          if (filter != StaffContractFilter.none ||
              (view.byContract[filter] ?? 0) > 0)
            _contractChip(context, filter),
        if (view.documentsVisible)
          EteeloFilterChip(
            label: l10n.staffIncompleteFilter,
            count: view.incomplete,
            selected: query.incompleteOnly,
            color: AppColors.staffPartialInk,
            soft: AppColors.feeStatusPartialSoft,
            ink: AppColors.staffPartialInk,
            icon: Icons.folder_off_outlined,
            onTap: onIncompleteToggled,
          ),
      ],
    );
  }

  Widget _contractChip(BuildContext context, StaffContractFilter filter) {
    final tone = StaffContractTone.ofFilter(filter);
    return EteeloFilterChip(
      label: StaffLabels.contractFilter(AppLocalizations.of(context)!, filter),
      count: view.byContract[filter] ?? 0,
      selected: query.contract == filter,
      color: tone.color,
      soft: tone.soft,
      ink: tone.ink,
      icon: tone.icon,
      onTap: () => onContractToggled(filter),
    );
  }
}
