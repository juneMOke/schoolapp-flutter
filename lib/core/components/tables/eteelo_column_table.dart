import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Une rangée de cellules aux largeurs partagées par l'en-tête et les lignes :
/// `null` = la colonne qui prend le reste.
class EteeloColumns extends StatelessWidget {
  final List<double?> widths;
  final List<Widget> cells;

  const EteeloColumns({super.key, required this.widths, required this.cells})
    : assert(widths.length == cells.length);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, cell) in cells.indexed)
        if (widths[index] == null)
          Expanded(child: cell)
        else
          SizedBox(width: widths[index], child: cell),
    ],
  );
}

/// Un tableau à colonnes fixes (récapitulatifs du Pointage et de l'appel,
/// livre de paie, avances, historique) : un en-tête gris, des lignes
/// filetées, et un défilement horizontal sous [minWidth].
class EteeloColumnTable extends StatelessWidget {
  final double minWidth;
  final List<double?> widths;
  final List<String> headers;

  /// Colonnes dont l'en-tête s'aligne à droite (montants).
  final Set<int> endAligned;
  final int rowCount;
  final Widget Function(BuildContext context, int index) row;

  /// Une ligne de pied (total), facultative.
  final Widget? footer;

  const EteeloColumnTable({
    super.key,
    required this.minWidth,
    required this.widths,
    required this.headers,
    required this.rowCount,
    required this.row,
    this.endAligned = const {},
    this.footer,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.brSm,
              ),
              child: EteeloColumns(
                widths: widths,
                cells: [
                  for (final (index, text) in headers.indexed)
                    Text(
                      text.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      textAlign: endAligned.contains(index)
                          ? TextAlign.end
                          : TextAlign.start,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMutedAa,
                      ),
                    ),
                ],
              ),
            ),
            for (var index = 0; index < rowCount; index++) row(context, index),
            ?footer,
          ],
        ),
      ),
    ),
  );
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

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: EteeloColumns(widths: widths, cells: cells),
    ),
  );
}
