import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/tables/data_table_density.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Header uniforme de table avec tri optionnel.
class DataTableHeader extends StatelessWidget {
  final List<DataTableColumnDef> columns;
  final int? activeSortColumn;
  final bool sortAscending;
  final OnDataTableSort? onSortChanged;
  final bool showLeadingSlot;
  final bool showTrailingSlot;
  final DataTableDensity density;

  /// Habillage teinté, ou `null` pour l'en-tête blanc historique.
  final DataTableTone? tone;

  const DataTableHeader({
    super.key,
    required this.columns,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.showLeadingSlot,
    required this.showTrailingSlot,
    this.density = DataTableDensity.comfortable,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EteeloDataTableTheme.headerHorizontalPadding,
        vertical: density.headerVerticalPadding,
      ),
      color: tone?.header ?? EteeloDataTableTheme.headerBackground,
      child: Row(
        children: [
          if (showLeadingSlot) ...[
            const SizedBox(width: EteeloDataTableTheme.leadingSlotWidth),
            const SizedBox(width: EteeloDataTableTheme.slotGap),
          ],
          ..._buildColumnHeaders(),
          if (showTrailingSlot) ...[
            const SizedBox(width: EteeloDataTableTheme.slotGap),
            const SizedBox(width: EteeloDataTableTheme.trailingSlotWidth),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildColumnHeaders() {
    final widgets = <Widget>[];

    for (var index = 0; index < columns.length; index++) {
      final column = columns[index];
      widgets.add(
        Expanded(
          flex: column.flex,
          child: _DataTableHeaderCell(
            column: column,
            columnIndex: index,
            activeSortColumn: activeSortColumn,
            sortAscending: sortAscending,
            onSortChanged: onSortChanged,
            tone: tone,
          ),
        ),
      );
      if (index < columns.length - 1) {
        widgets.add(const SizedBox(width: EteeloDataTableTheme.slotGap));
      }
    }

    return widgets;
  }
}

class _DataTableHeaderCell extends StatelessWidget {
  final DataTableColumnDef column;
  final int columnIndex;
  final int? activeSortColumn;
  final bool sortAscending;
  final OnDataTableSort? onSortChanged;
  final DataTableTone? tone;

  const _DataTableHeaderCell({
    required this.column,
    required this.columnIndex,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortIndex = column.sortIndex ?? columnIndex;
    final isSortable = column.sortable && onSortChanged != null;
    final isActive = activeSortColumn == sortIndex;
    final sortStateLabel = isActive
        ? (sortAscending
              ? l10n.dataTableSortAscending
              : l10n.dataTableSortDescending)
        : l10n.dataTableSortNone;

    final label = EteeloOverflowText(
      column.label.toUpperCase(),
      style: EteeloDataTableTheme.headerLabelStyle.copyWith(
        color: isActive
            ? (tone?.headerInkSorted ??
                  EteeloDataTableTheme.headerSortActiveColor)
            : (tone?.headerInk ?? EteeloDataTableTheme.headerSortInactiveColor),
      ),
    );

    if (!isSortable) {
      return Semantics(
        header: true,
        child: Align(alignment: Alignment.centerLeft, child: label),
      );
    }

    void sort() => onSortChanged!(sortIndex, isActive ? !sortAscending : true);

    return Semantics(
      header: true,
      button: true,
      focusable: true,
      label: column.label,
      value: sortStateLabel,
      child: EteeloActivatable(
        onActivate: sort,
        builder: (context, highlight) => AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: highlight.focused
                ? Border.all(
                    color: EteeloDataTableTheme.focusRingColor,
                    width: EteeloDataTableTheme.focusRingWidth,
                  )
                : null,
          ),
          padding: const EdgeInsets.all(EteeloDataTableTheme.focusRingOffset),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: 2),
                AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: Icon(
                    key: ValueKey('sort-$sortIndex-$sortAscending-$isActive'),
                    isActive
                        ? (sortAscending
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded)
                        : Icons.unfold_more_rounded,
                    size: 12,
                    color: isActive
                        ? (tone?.headerInkSorted ??
                              EteeloDataTableTheme.headerSortActiveColor)
                        : (tone?.headerInk ??
                              EteeloDataTableTheme.headerSortInactiveColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
