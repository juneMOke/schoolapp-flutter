import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/tables/data_table_density.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
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

  const DataTableHeader({
    super.key,
    required this.columns,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.showLeadingSlot,
    required this.showTrailingSlot,
    this.density = DataTableDensity.comfortable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EteeloDataTableTheme.headerHorizontalPadding,
        vertical: density.headerVerticalPadding,
      ),
      color: EteeloDataTableTheme.headerBackground,
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

class _DataTableHeaderCell extends StatefulWidget {
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
  State<_DataTableHeaderCell> createState() => _DataTableHeaderCellState();
}

class _DataTableHeaderCellState extends State<_DataTableHeaderCell> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortIndex = widget.column.sortIndex ?? widget.columnIndex;
    final isSortable = widget.column.sortable && widget.onSortChanged != null;
    final isActive = widget.activeSortColumn == sortIndex;
    final sortStateLabel = isActive
        ? (widget.sortAscending
              ? l10n.dataTableSortAscending
              : l10n.dataTableSortDescending)
        : l10n.dataTableSortNone;

    final label = Text(
      widget.column.label.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: EteeloDataTableTheme.headerLabelStyle.copyWith(
        color: isActive
            ? EteeloDataTableTheme.headerSortActiveColor
            : EteeloDataTableTheme.headerSortInactiveColor,
      ),
    );

    if (!isSortable) {
      return Semantics(
        header: true,
        child: Align(alignment: Alignment.centerLeft, child: label),
      );
    }

    return Semantics(
      header: true,
      button: true,
      focusable: true,
      label: widget.column.label,
      value: sortStateLabel,
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) {
          if (_isFocused == value) return;
          setState(() => _isFocused = value);
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onSortChanged!(
                sortIndex,
                isActive ? !widget.sortAscending : true,
              );
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: _isFocused
                ? Border.all(
                    color: EteeloDataTableTheme.focusRingColor,
                    width: EteeloDataTableTheme.focusRingWidth,
                  )
                : null,
          ),
          padding: EdgeInsets.all(EteeloDataTableTheme.focusRingOffset),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => widget.onSortChanged!(
                sortIndex,
                isActive ? !widget.sortAscending : true,
              ),
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
                        key: ValueKey(
                          'sort-$sortIndex-${widget.sortAscending}-$isActive',
                        ),
                        isActive
                            ? (widget.sortAscending
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
          ),
        ),
      ),
    );
  }
}
