import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';

/// Un élément de [SelectableListCard].
class SelectableListItem {
  final String id;
  final String label;

  /// Une ligne de précision sous le libellé (classe, matricule…).
  final String? caption;

  const SelectableListItem({
    required this.id,
    required this.label,
    this.caption,
  });
}

/// La colonne de choix d'un écran liste + fiche (cf. `MasterDetailLayout`) :
/// un titre, un filtre quand la liste est longue, et l'élément ouvert marqué.
///
/// Remplace sur grand écran une liste déroulante au-dessus du contenu : tout
/// le monde est visible, et passer au suivant est un clic (ou ↓ puis Entrée).
class SelectableListCard extends StatefulWidget {
  final String title;
  final List<SelectableListItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  /// Libellé du filtre, affiché au-delà de [filterThreshold] éléments.
  final String filterLabel;

  static const filterThreshold = 8;

  const SelectableListCard({
    super.key,
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.filterLabel,
  });

  @override
  State<SelectableListCard> createState() => _SelectableListCardState();
}

class _SelectableListCardState extends State<SelectableListCard> {
  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  List<SelectableListItem> get _visible {
    final query = _filter.text.trim();
    if (query.isEmpty) return widget.items;
    return [
      for (final item in widget.items)
        if (SearchNormalizationHelper.containsAllWords([
          item.label,
          item.caption,
        ], query))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.items.length > SelectableListCard.filterThreshold) ...[
              EteeloTextInput(
                controller: _filter,
                label: widget.filterLabel,
                hideLabel: true,
                placeholder: widget.filterLabel,
                capitalization: EteeloTextCapitalization.none,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final item in visible)
              _Row(
                item: item,
                selected: item.id == widget.selectedId,
                onTap: () => widget.onSelected(item.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final SelectableListItem item;
  final bool selected;
  final VoidCallback onTap;

  const _Row({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final caption = item.caption;
    return Semantics(
      selected: selected,
      button: true,
      child: EteeloActivatable(
        onActivate: onTap,
        builder: (context, highlight) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.statePressed
                : highlight.any
                ? AppColors.stateHover
                : null,
            borderRadius: AppRadius.brSm,
            border: Border(
              left: BorderSide(
                color: selected || highlight.focused
                    ? AppColors.bleuArdoise
                    : Colors.transparent,
                width: EteeloDataTableTheme.rowLeadingBorderWidth,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
              if (caption != null && caption.isNotEmpty)
                Text(
                  caption,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
