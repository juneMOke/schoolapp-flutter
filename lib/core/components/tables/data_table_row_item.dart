import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_widget.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';

/// Ligne uniforme de table avec gestion hover et trailing centralises.
class DataTableRowItem extends StatefulWidget {
  final DataTableRowSpec row;
  final List<DataTableColumnDef> columns;
  final bool isEven;
  final Map<DataTableTrailingType, DataTableTrailingBuilder> trailingBuilders;

  const DataTableRowItem({
    super.key,
    required this.row,
    required this.columns,
    required this.isEven,
    this.trailingBuilders = const {},
  });

  @override
  State<DataTableRowItem> createState() => _DataTableRowItemState();
}

class _DataTableRowItemState extends State<DataTableRowItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.row.onTap != null;
    final hasLeading = widget.row.leading != null;
    final hasTrailing = widget.row.trailing.type != DataTableTrailingType.none;
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: hasTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTap: widget.row.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: EteeloDataTableTheme.rowHoverDuration,
          height: EteeloDataTableTheme.rowHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: EteeloDataTableTheme.rowHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? EteeloDataTableTheme.rowHoverBackground
                : EteeloDataTableTheme.rowEvenBackground,
            border: Border(
              left: BorderSide(
                color: isActive
                    ? EteeloDataTableTheme.rowHoverLeadingBorder
                    : Colors.transparent,
                width: EteeloDataTableTheme.rowLeadingBorderWidth,
              ),
            ),
          ),
          child: Row(
            children: [
              if (hasLeading) ...[
                SizedBox(
                  width: EteeloDataTableTheme.leadingSlotWidth,
                  child: widget.row.leading,
                ),
                const SizedBox(width: EteeloDataTableTheme.slotGap),
              ],
              ..._buildCells(),
              if (hasTrailing) ...[
                const SizedBox(width: EteeloDataTableTheme.slotGap),
                SizedBox(
                  width: EteeloDataTableTheme.trailingSlotWidth,
                  child: Align(
                    alignment: Alignment.center,
                    child: DataTableTrailingWidget(
                      spec: widget.row.trailing,
                      customBuilders: widget.trailingBuilders,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCells() {
    final widgets = <Widget>[];

    for (var index = 0; index < widget.columns.length; index++) {
      final column = widget.columns[index];
      final cell = index < widget.row.cells.length
          ? widget.row.cells[index]
          : const DataTableCellSpec(text: '');

      widgets.add(
        Expanded(
          flex: column.flex,
          child: cell.child != null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: cell.child,
                  ),
                )
              : Text(
                  cell.text.isNotEmpty ? cell.text : '—',
                  textAlign: cell.textAlign,
                  overflow: TextOverflow.ellipsis,
                  style: _resolveCellStyle(cell.variant),
                ),
        ),
      );

      if (index < widget.columns.length - 1) {
        widgets.add(const SizedBox(width: EteeloDataTableTheme.slotGap));
      }
    }

    return widgets;
  }

  TextStyle _resolveCellStyle(DataTableCellTextVariant variant) {
    return switch (variant) {
      DataTableCellTextVariant.strong => EteeloDataTableTheme.cellStrongStyle,
      DataTableCellTextVariant.mono => EteeloDataTableTheme.cellMonoStyle,
      DataTableCellTextVariant.regular => EteeloDataTableTheme.cellRegularStyle,
    };
  }
}
