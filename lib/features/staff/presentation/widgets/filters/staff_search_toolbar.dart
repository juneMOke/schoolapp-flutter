import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'outils des écrans RH : recherche, catégorie et bascule
/// cartes/liste. Partagée par le fichier du personnel et le registre du
/// Pointage ; la catégorie et la bascule sont facultatives.
class StaffSearchToolbar extends StatefulWidget {
  final String text;
  final String label;
  final String placeholder;
  final ValueChanged<String> onTextChanged;

  /// `null` : pas de sélecteur de catégorie.
  final ValueChanged<StaffCategory?>? onCategoryChanged;
  final StaffCategory? category;

  /// `null` : pas de bascule cartes/liste.
  final ValueChanged<StaffViewMode>? onViewModeChanged;
  final StaffViewMode viewMode;

  const StaffSearchToolbar({
    super.key,
    required this.text,
    required this.label,
    required this.placeholder,
    required this.onTextChanged,
    this.onCategoryChanged,
    this.category,
    this.onViewModeChanged,
    this.viewMode = StaffViewMode.grid,
  });

  @override
  State<StaffSearchToolbar> createState() => _StaffSearchToolbarState();
}

class _StaffSearchToolbarState extends State<StaffSearchToolbar> {
  late final TextEditingController _search = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(covariant StaffSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // « Réinitialiser les filtres » doit aussi vider le champ : il afficherait
    // sinon une recherche que le calcul ne connaît plus.
    if (widget.text != _search.text) _search.text = widget.text;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onCategory = widget.onCategoryChanged;
    final onViewMode = widget.onViewModeChanged;
    return Wrap(
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
            label: widget.label,
            placeholder: widget.placeholder,
            capitalization: EteeloTextCapitalization.none,
            onChanged: widget.onTextChanged,
          ),
        ),
        if (onCategory != null)
          SizedBox(
            width: AppDimensions.staffCategoryWidth,
            child: EteeloSelectInput<String>(
              label: l10n.staffCategoryLabel,
              value: widget.category?.wire ?? '',
              onChanged: (wire) => onCategory(StaffCategory.fromWire(wire)),
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
        if (onViewMode != null)
          SegmentedTabFilter<StaffViewMode>(
            semanticsLabel: l10n.staffViewLabel,
            selected: widget.viewMode,
            onSelected: onViewMode,
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
    );
  }
}
