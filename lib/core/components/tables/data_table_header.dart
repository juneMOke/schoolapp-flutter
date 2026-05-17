import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Header uniforme de table avec tri optionnel.
class DataTableHeader extends StatelessWidget {
  final List<DataTableColumnDef> columns;
  final int? activeSortColumn;
  final bool sortAscending;
  final OnDataTableSort? onSortChanged;
  final bool showLeadingSlot;
  final bool showTrailingSlot;

  const DataTableHeader({
    super.key,
    required this.columns,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.showLeadingSlot,
    required this.showTrailingSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: EteeloDataTableTheme.headerHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: EteeloDataTableTheme.headerHorizontalPadding,
      ),
      decoration: const BoxDecoration(
        gradient: EteeloDataTableTheme.headerGradient,
      ),
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

  const _DataTableHeaderCell({
    required this.column,
    required this.columnIndex,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortIndex = column.sortIndex ?? columnIndex;
    final isSortable = column.sortable && onSortChanged != null;
    final isActive = activeSortColumn == sortIndex;

    final label = Text(
      column.label.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: EteeloDataTableTheme.headerLabelStyle.copyWith(
        color: isActive
            ? EteeloDataTableTheme.headerSortActiveColor
            : EteeloDataTableTheme.headerSortInactiveColor,
      ),
    );

    if (!isSortable) {
      return Align(alignment: Alignment.centerLeft, child: label);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () =>
            onSortChanged!(sortIndex, isActive ? !sortAscending : true),
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
                      ? EteeloDataTableTheme.headerSortActiveColor
                      : EteeloDataTableTheme.headerSortInactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
