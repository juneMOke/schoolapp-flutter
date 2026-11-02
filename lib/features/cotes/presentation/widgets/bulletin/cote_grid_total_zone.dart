import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_row_frame.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_rubrique.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_percent_meter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _padding = EdgeInsets.symmetric(horizontal: AppSpacing.md);

/// La colonne figée de droite : le total de la portée, ligne par ligne.
class CoteGridTotalZone extends StatelessWidget {
  final CoteGridContext grid;

  const CoteGridTotalZone({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final heights = grid.heights;
    return CoteStudentBuilder(
      studentId: grid.studentId,
      builder: (context, state) {
        final calc = state.calcs[grid.studentId]!;
        final maxima = formatCentis(calc.maxScope);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: grid.rowsTop),
            for (final row in grid.rows)
              coteRowReveal(row, switch (row) {
                final CoteRubriqueRow r => CoteRubriqueStrip(
                  row: r,
                  grid: grid,
                ),
                final CoteCourseRow r => _courseTotal(calc, r),
                final CoteSubtotalRow r => _subtotal(calc, r),
              }),
            Container(
              height: heights.maxima,
              color: AppColors.coteMaxSurface,
              padding: _padding,
              alignment: Alignment.centerRight,
              child: Text(maxima, maxLines: 1, style: coteMaximaStyle()),
            ),
            _grandTotal(AppLocalizations.of(context)!, calc),
            if (grid.hasGroupTotals)
              Container(height: heights.percent, color: AppColors.bleuArdoise),
          ],
        );
      },
    );
  }

  Widget _subtotal(CoteEleveCalc calc, CoteSubtotalRow row) {
    var total = 0, filled = 0, scope = 0;
    for (final cours in row.rubrique.allCours) {
      final part = calc.cours[cours.coursId];
      if (part == null) continue;
      total += part.total;
      filled += part.maxFilled;
      scope += part.maxScope;
    }
    return CoteSubtotalStrip(
      row: row,
      grid: grid,
      child: Container(
        padding: _padding,
        alignment: Alignment.centerRight,
        child: CoteTotalValue(
          obtained: formatCentis(total),
          max: formatCentis(scope),
          percent: roundedPercent(total, filled),
          ink: coteScoreInk(total, filled),
          fails: coteScoreFails(total, filled),
          showMeter: !grid.metrics.phone,
          dense: grid.metrics.dense,
        ),
      ),
    );
  }

  Widget _courseTotal(CoteEleveCalc calc, CoteCourseRow row) {
    final part = calc.cours[row.cours.coursId];
    return CoteCourseRowFrame(
      row: row,
      grid: grid,
      padding: _padding,
      alignment: Alignment.centerRight,
      child: CoteTotalValue(
        obtained: formatCentis(part?.total ?? 0),
        max: formatCentis(part?.maxScope ?? 0),
        percent: part?.pct,
        ink: part == null ? null : coteScoreInk(part.total, part.maxFilled),
        fails: part != null && coteScoreFails(part.total, part.maxFilled),
        showMeter: !grid.metrics.phone,
        dense: grid.metrics.dense,
      ),
    );
  }

  Widget _grandTotal(AppLocalizations l10n, CoteEleveCalc calc) {
    final percent = calc.pct;
    final ink = coteScoreInk(calc.total, calc.maxFilled);
    return Container(
      height: grid.heights.total,
      color: AppColors.bleuProfond,
      padding: _padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              formatCentis(calc.total),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: coteDarkRowStyle(
                strong: true,
              ).copyWith(decoration: coteScoreMark(calc.total, calc.maxFilled)),
            ),
          ),
          if (!grid.metrics.phone) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: ink ?? AppColors.stateFocusOnDark,
                borderRadius: AppRadius.brPill,
              ),
              child: Text(
                percent == null ? '—' : l10n.cotePercent(percent),
                maxLines: 1,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
