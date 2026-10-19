import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_frozen_column.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_min_width_scroll.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une rangée de cellules aux largeurs partagées par l'en-tête et les lignes :
/// `null` = la colonne qui prend le reste.
///
/// Sous un [EteeloFrozenColumn], la première cellule reste à l'écran quand le
/// tableau défile de côté, posée sur [frozenBackground].
class EteeloColumns extends StatelessWidget {
  final List<double?> widths;
  final List<Widget> cells;

  /// Fond de la cellule figée : il masque les colonnes qui passent dessous.
  final Color frozenBackground;

  const EteeloColumns({
    super.key,
    required this.widths,
    required this.cells,
    this.frozenBackground = AppColors.surfaceRaised,
  }) : assert(widths.length == cells.length);

  Widget _sized(int index, Widget cell) => widths[index] == null
      ? Expanded(child: cell)
      : SizedBox(width: widths[index], child: cell);

  @override
  Widget build(BuildContext context) {
    final frozen = EteeloFrozenColumn.maybeOf(context);
    if (frozen == null) {
      return Row(
        children: [for (final (i, cell) in cells.indexed) _sized(i, cell)],
      );
    }
    return Stack(
      children: [
        Row(
          children: [
            // La place reste réservée : les autres colonnes ne bougent pas.
            _sized(0, const SizedBox.shrink()),
            for (final (i, cell) in cells.indexed.skip(1)) _sized(i, cell),
          ],
        ),
        AnimatedBuilder(
          animation: frozen.controller,
          builder: (context, child) => Positioned(
            left: frozen.offset,
            top: 0,
            bottom: 0,
            width: frozen.width,
            child: child!,
          ),
          child: ColoredBox(
            color: frozenBackground,
            child: Align(alignment: Alignment.centerLeft, child: cells.first),
          ),
        ),
      ],
    );
  }
}

/// Un tableau à colonnes fixes (récapitulatifs du Pointage et de l'appel,
/// livre de paie, avances, historique) : un en-tête gris, des lignes
/// filetées, et un défilement horizontal sous [minWidth]
/// ([EteeloMinWidthScroll]).
class EteeloColumnTable extends StatefulWidget {
  final double minWidth;
  final List<double?> widths;
  final List<String> headers;

  /// Colonnes dont l'en-tête s'aligne à droite (montants).
  final Set<int> endAligned;
  final int rowCount;
  final Widget Function(BuildContext context, int index) row;

  /// Une ligne de pied (total), facultative.
  final Widget? footer;

  /// La première colonne (qui, de quoi) reste à l'écran quand le tableau
  /// défile de côté (cf. [EteeloFrozenColumn]).
  final bool frozenFirstColumn;

  const EteeloColumnTable({
    super.key,
    required this.minWidth,
    required this.widths,
    required this.headers,
    required this.rowCount,
    required this.row,
    this.endAligned = const {},
    this.footer,
    this.frozenFirstColumn = false,
  });

  @override
  State<EteeloColumnTable> createState() => _EteeloColumnTableState();
}

class _EteeloColumnTableState extends State<EteeloColumnTable> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// La colonne figée dans la largeur plancher : la sienne, ou ce que les
  /// autres laissent (moins les marges de la rangée).
  double get _frozenWidth {
    final own = widget.widths.first;
    if (own != null) return own;
    final others = widget.widths
        .skip(1)
        .fold<double>(0, (sum, width) => sum + (width ?? 0));
    return widget.minWidth - others - 2 * AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) {
    final table = EteeloMinWidthScroll(
      minWidth: widget.minWidth,
      controller: _scroll,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brSm,
            ),
            child: EteeloColumns(
              widths: widget.widths,
              frozenBackground: AppColors.surfaceAlt,
              cells: [
                for (final (index, text) in widget.headers.indexed)
                  EteeloOverflowText(
                    text.toUpperCase(),
                    textAlign: widget.endAligned.contains(index)
                        ? TextAlign.end
                        : TextAlign.start,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
              ],
            ),
          ),
          for (var index = 0; index < widget.rowCount; index++)
            widget.row(context, index),
          ?widget.footer,
        ],
      ),
    );
    if (!widget.frozenFirstColumn) return table;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= widget.minWidth
          ? table
          : EteeloFrozenColumn(
              controller: _scroll,
              width: _frozenWidth,
              child: table,
            ),
    );
  }
}

/// Une ligne de [EteeloColumnTable] : filet bas, toucher facultatif.
class EteeloColumnTableRow extends StatelessWidget {
  final List<double?> widths;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? background;

  const EteeloColumnTableRow({
    super.key,
    required this.widths,
    required this.cells,
    this.onTap,
    this.background,
  });

  /// Le style des chiffres d'une cellule : tabulaires, pour qu'ils
  /// s'alignent d'une ligne à l'autre.
  static TextStyle figures({Color? color, bool strong = false}) =>
      (strong ? AppTypography.labelLarge : AppTypography.bodyMedium).copyWith(
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Le fond est porté par le `Material` et non par le `Container` : l'encre
  // de l'`InkWell` (survol, focus, appui) se peint SOUS l'enfant, et un fond
  // opaque posé dessus la masquait — la ligne ne réagissait plus à rien.
  @override
  Widget build(BuildContext context) => Material(
    type: background == null ? MaterialType.transparency : MaterialType.canvas,
    color: background,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: EteeloColumns(widths: widths, cells: cells),
      ),
    ),
  );
}
