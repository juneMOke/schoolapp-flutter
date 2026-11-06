import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_row_frame.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_rubrique.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La colonne figée de gauche : les cours, leurs domaines, les libellés de pied.
class CoteGridCourseZone extends StatelessWidget {
  final CoteGridContext grid;

  const CoteGridCourseZone({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heights = grid.heights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // L'en-tête vit dans la pile de la grille, collé au haut de l'écran.
        SizedBox(height: grid.rowsTop),
        for (final row in grid.rows)
          coteRowReveal(row, switch (row) {
            final CoteRubriqueRow r => CoteRubriqueStrip(row: r, grid: grid),
            final CoteCourseRow r => _CourseLabel(row: r, grid: grid),
            final CoteSubtotalRow r => CoteSubtotalStrip(
              row: r,
              grid: grid,
              child: _SubtotalLabel(row: r),
            ),
          }),
        _FootLabel(
          label: l10n.coteMaxima.toUpperCase(),
          height: heights.maxima,
          background: AppColors.coteMaxSurface,
          style: coteMaximaStyle(),
        ),
        _FootLabel(
          label: l10n.coteTotalObtained.toUpperCase(),
          height: heights.total,
          background: AppColors.bleuProfond,
          style: coteDarkRowStyle(),
        ),
        if (grid.hasGroupTotals)
          _FootLabel(
            label: l10n.cotePercentRow.toUpperCase(),
            height: heights.percent,
            background: AppColors.bleuArdoise,
            style: coteDarkRowStyle(),
          ),
      ],
    );
  }
}

class _SubtotalLabel extends StatelessWidget {
  final CoteSubtotalRow row;

  const _SubtotalLabel({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.coteSubtotal,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: row.tone.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Le nom entier du cours : il va à la ligne plutôt que de se couper, et ne
/// s'ellipse qu'au-delà de ce que la ligne peut contenir.
class _CourseLabel extends StatelessWidget {
  final CoteCourseRow row;
  final CoteGridContext grid;

  const _CourseLabel({required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    // Une colonne étroite prend une ligne de plus, en petit : le nom reste entier.
    final narrow = grid.metrics.courseWidth < AppDimensions.coteCourseColumn;
    return CoteCourseRowFrame(
      row: row,
      grid: grid,
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: AppDimensions.coteCourseMarkWidth,
            height: AppDimensions.coteCourseMarkHeight,
            color: row.tone.mark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EteeloOverflowText(
              row.cours.branche,
              maxLines: narrow ? 3 : 2,
              style:
                  (narrow ? AppTypography.bodySmall : AppTypography.bodyMedium)
                      .copyWith(
                        color: AppColors.noirChaud,
                        fontWeight: FontWeight.w500,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FootLabel extends StatelessWidget {
  final String label;
  final double height;
  final Color background;
  final TextStyle style;

  const _FootLabel({
    required this.label,
    required this.height,
    required this.background,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
