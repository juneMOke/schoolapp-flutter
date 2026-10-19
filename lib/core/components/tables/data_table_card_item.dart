import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/tables/data_table_cell_content.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_widget.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Une ligne de table en carte, sur un téléphone : la cellule [titleColumn]
/// en titre (avec la vignette et l'action de ligne), chaque cellule suivante
/// sur sa ligne, nommée par sa colonne.
///
/// Comprimées en colonnes à 360 dp, les valeurs se coupaient — un montant de
/// reçu tombait à ~40 dp. En carte, chacune a la largeur de l'écran.
class DataTableCardItem extends StatelessWidget {
  final DataTableRowSpec row;
  final List<DataTableColumnDef> columns;
  final Map<DataTableTrailingType, DataTableTrailingBuilder> trailingBuilders;

  /// Cf. `DataTableViewConfig.cardTitleColumn`.
  final int titleColumn;

  const DataTableCardItem({
    super.key,
    required this.row,
    required this.columns,
    this.trailingBuilders = const {},
    this.titleColumn = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Même contrat que la ligne : un bouton au clavier dès qu'elle s'ouvre.
    return Semantics(
      button: row.onTap != null,
      selected: row.selected ? true : null,
      enabled: row.onTap != null ? true : null,
      child: EteeloActivatable(
        onActivate: row.onTap,
        builder: (context, highlight) => Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          foregroundDecoration: highlight.focused
              ? BoxDecoration(
                  border: Border.all(
                    color: EteeloDataTableTheme.focusRingColor,
                    width: EteeloDataTableTheme.focusRingWidth,
                  ),
                )
              : null,
          color: row.selected || highlight.hovered
              ? EteeloDataTableTheme.rowSelectedBackground
              : EteeloDataTableTheme.rowEvenBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _title(),
              for (var i = 0; i < columns.length; i++)
                if (_fieldCellAt(i) case final cell?)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppDimensions.spacingXS,
                    ),
                    child: _field(columns[i].label, cell),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// `null` pour le titre, et pour une cellule absente ou vide : une carte
  /// ne liste pas des tirets.
  DataTableCellSpec? _fieldCellAt(int index) {
    if (index == titleColumn || index >= row.cells.length) return null;
    final cell = row.cells[index];
    final empty = cell.child == null && cell.text.trim().isEmpty;
    return empty ? null : cell;
  }

  Widget _title() {
    final leading = row.leading;
    final first = titleColumn < row.cells.length
        ? row.cells[titleColumn]
        : null;
    return Row(
      children: [
        if (leading != null) ...[
          SizedBox(
            width: EteeloDataTableTheme.leadingSlotWidth,
            child: leading,
          ),
          const SizedBox(width: EteeloDataTableTheme.slotGap),
        ],
        Expanded(
          child: first == null
              ? Text(row.displayName, style: AppTextStyles.bodyStrong)
              : DataTableCellContent(cell: first),
        ),
        if (row.trailing.type != DataTableTrailingType.none) ...[
          const SizedBox(width: EteeloDataTableTheme.slotGap),
          DataTableTrailingWidget(
            spec: row.trailing,
            customBuilders: trailingBuilders,
          ),
        ],
      ],
    );
  }

  Widget _field(String label, DataTableCellSpec cell) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMutedAa),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Flexible(
          flex: 2,
          child: DataTableCellContent(
            cell: cell,
            childAlignment: Alignment.centerRight,
            crossAxisAlignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}
