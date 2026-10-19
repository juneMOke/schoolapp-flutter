import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';

/// Le contenu d'une cellule — widget fourni, texte seul, ou texte et ligne
/// secondaire — tel que la ligne de table et sa carte de téléphone le
/// rendent tous deux.
class DataTableCellContent extends StatelessWidget {
  final DataTableCellSpec cell;

  /// Alignement d'un widget fourni ; les textes suivent `cell.textAlign`.
  final AlignmentGeometry childAlignment;

  /// Alignement horizontal du bloc texte + ligne secondaire.
  final CrossAxisAlignment crossAxisAlignment;

  const DataTableCellContent({
    super.key,
    required this.cell,
    this.childAlignment = Alignment.centerLeft,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final child = cell.child;
    if (child != null) {
      return Align(
        alignment: childAlignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: childAlignment,
          child: child,
        ),
      );
    }
    final primary = EteeloOverflowText(
      cell.text.isNotEmpty ? cell.text : '—',
      textAlign: cell.textAlign,
      style: styleOf(cell.variant, cell.color),
    );
    final secondary = cell.secondaryText;
    if (secondary == null || secondary.isEmpty) return primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        primary,
        const SizedBox(height: 2),
        _maybeExplained(
          cell.secondaryTooltip,
          Text(
            secondary,
            textAlign: cell.textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styleOf(cell.secondaryVariant, cell.secondaryColor),
          ),
        ),
      ],
    );
  }

  static TextStyle styleOf(DataTableCellTextVariant variant, [Color? color]) {
    final style = switch (variant) {
      DataTableCellTextVariant.strong => EteeloDataTableTheme.cellStrongStyle,
      DataTableCellTextVariant.mono => EteeloDataTableTheme.cellMonoStyle,
      DataTableCellTextVariant.regular => EteeloDataTableTheme.cellRegularStyle,
    };
    return color == null ? style : style.copyWith(color: color);
  }

  /// Enrobe la ligne secondaire d'une explication, quand il y en a une.
  ///
  /// [Tooltip] porte aussi l'étiquette d'accessibilité : l'explication est
  /// **lue**, pas seulement survolée — une mention qui ne s'obtient qu'à la
  /// souris n'existe pas sur une tablette.
  static Widget _maybeExplained(String? tooltip, Widget child) =>
      tooltip == null || tooltip.isEmpty
      ? child
      : Tooltip(message: tooltip, child: child);
}
