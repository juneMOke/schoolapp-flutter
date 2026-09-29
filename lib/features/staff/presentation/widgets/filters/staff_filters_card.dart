import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de filtres : recherche, catégorie et affichage sur une ligne, puis
/// les puces de contrat et « Dossier incomplet ». Tous les filtres se
/// combinent.
class StaffFiltersCard extends StatefulWidget {
  final StaffFileQuery query;
  final StaffFileView view;
  final StaffViewMode viewMode;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<StaffCategory?> onCategoryChanged;
  final ValueChanged<StaffContractFilter?> onContractToggled;
  final VoidCallback onIncompleteToggled;
  final ValueChanged<StaffViewMode> onViewModeChanged;

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
  State<StaffFiltersCard> createState() => _StaffFiltersCardState();
}

class _StaffFiltersCardState extends State<StaffFiltersCard> {
  late final TextEditingController _search = TextEditingController(
    text: widget.query.text,
  );

  @override
  void didUpdateWidget(covariant StaffFiltersCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // « Réinitialiser les filtres » doit aussi vider le champ : il afficherait
    // sinon une recherche que le calcul ne connaît plus.
    if (widget.query.text != _search.text) _search.text = widget.query.text;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.staffSearchMinWidth,
                  maxWidth: AppDimensions.staffSearchMaxWidth,
                ),
                child: EteeloTextInput(
                  controller: _search,
                  label: l10n.staffSearchLabel,
                  placeholder: l10n.staffSearchPlaceholder,
                  capitalization: EteeloTextCapitalization.none,
                  onChanged: widget.onTextChanged,
                ),
              ),
              SizedBox(
                width: AppDimensions.staffCategoryWidth,
                child: EteeloSelectInput<String>(
                  label: l10n.staffCategoryLabel,
                  value: widget.query.category?.wire ?? '',
                  onChanged: (wire) =>
                      widget.onCategoryChanged(StaffCategory.fromWire(wire)),
                  items: [
                    EteeloSelectItem(value: '', label: l10n.staffCategoryAll),
                    for (final category in StaffCategory.values)
                      EteeloSelectItem(
                        value: category.wire,
                        label: StaffLabels.category(l10n, category),
                      ),
                  ],
                ),
              ),
              SegmentedTabFilter<StaffViewMode>(
                semanticsLabel: l10n.staffViewLabel,
                selected: widget.viewMode,
                onSelected: widget.onViewModeChanged,
                options: [
                  SegmentedTabOption(
                    label: l10n.staffViewGrid,
                    value: StaffViewMode.grid,
                    icon: Icons.grid_view_outlined,
                  ),
                  SegmentedTabOption(
                    label: l10n.staffViewList,
                    value: StaffViewMode.list,
                    icon: Icons.view_list_outlined,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ContractChips(
            query: widget.query,
            view: widget.view,
            onContractToggled: widget.onContractToggled,
            onIncompleteToggled: widget.onIncompleteToggled,
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
        StaffFilterChip(
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
          StaffFilterChip(
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
    return StaffFilterChip(
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
