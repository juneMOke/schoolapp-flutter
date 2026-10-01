import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'outils des écrans RH : la barre commune ([EteeloSearchToolbar])
/// et, entre la recherche et la bascule, le sélecteur de catégorie d'agent.
/// Partagée par le fichier du personnel et le registre du Pointage.
class StaffSearchToolbar extends StatelessWidget {
  final String text;
  final String label;
  final String placeholder;
  final ValueChanged<String> onTextChanged;

  /// `null` : pas de sélecteur de catégorie.
  final ValueChanged<StaffCategory?>? onCategoryChanged;
  final StaffCategory? category;

  /// `null` : pas de bascule cartes/liste.
  final ValueChanged<CollectionViewMode>? onViewModeChanged;
  final CollectionViewMode viewMode;

  const StaffSearchToolbar({
    super.key,
    required this.text,
    required this.label,
    required this.placeholder,
    required this.onTextChanged,
    this.onCategoryChanged,
    this.category,
    this.onViewModeChanged,
    this.viewMode = CollectionViewMode.grid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onCategory = onCategoryChanged;
    return EteeloSearchToolbar(
      text: text,
      label: label,
      placeholder: placeholder,
      onTextChanged: onTextChanged,
      onViewModeChanged: onViewModeChanged,
      viewMode: viewMode,
      filters: [
        if (onCategory != null)
          SizedBox(
            width: AppDimensions.staffCategoryWidth,
            child: EteeloSelectInput<String>(
              label: l10n.staffCategoryLabel,
              value: category?.wire ?? '',
              onChanged: (wire) => onCategory(StaffCategory.fromWire(wire)),
              items: [
                EteeloSelectItem(value: '', label: l10n.staffCategoryAll),
                for (final value in StaffCategory.values)
                  EteeloSelectItem(
                    value: value.wire,
                    label: StaffLabels.category(l10n, value),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
