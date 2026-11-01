import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
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
            if (grid.hasGroupTotals)
              Container(height: heights.group, color: AppColors.blancCasse),
            _HeaderLabel(grid: grid, height: heights.header),
            for (final row in grid.rows)
              switch (row) {
                final CoteRubriqueRow r => _domainTotal(state, r),
                final CoteCourseRow r => _courseTotal(calc, r),
              },
            Container(
              height: heights.maxima,
              color: AppColors.blancCasse,
              padding: _padding,
              alignment: Alignment.centerRight,
              child: Text(maxima, maxLines: 1, style: coteMaximaStyle()),
            ),
            _grandTotal(calc),
            if (grid.hasGroupTotals)
              Container(height: heights.percent, color: AppColors.bleuArdoise),
          ],
        );
      },
    );
  }

  Widget _domainTotal(CoteSaisieReady state, CoteRubriqueRow row) {
    final calc = state.calcs[grid.studentId]!;
    var total = 0, filled = 0, scope = 0;
    for (final cours in row.rubrique.allCours) {
      final part = calc.cours[cours.coursId];
      if (part == null) continue;
      total += part.total;
      filled += part.maxFilled;
      scope += part.maxScope;
    }
    return Container(
      height: grid.heights.domain,
      color: row.tone.soft,
      padding: _padding,
      alignment: Alignment.centerRight,
      child: row.rubrique.produitSousTotal
          ? CoteTotalValue(
              obtained: formatCentis(total),
              max: formatCentis(scope),
              percent: roundedPercent(total, filled),
              showMeter: !grid.metrics.phone,
              dense: grid.metrics.dense,
            )
          : null,
    );
  }

  Widget _courseTotal(CoteEleveCalc calc, CoteCourseRow row) {
    final part = calc.cours[row.cours.coursId];
    return Container(
      height: grid.heights.course,
      padding: _padding,
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: CoteTotalValue(
        obtained: formatCentis(part?.total ?? 0),
        max: formatCentis(part?.maxScope ?? 0),
        percent: part?.pct,
        showMeter: !grid.metrics.phone,
        dense: grid.metrics.dense,
      ),
    );
  }

  Widget _grandTotal(CoteEleveCalc calc) {
    final percent = calc.pct;
    final low = percent != null && percent < 50;
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
              style: coteDarkRowStyle(strong: true),
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
                color: percent == null
                    ? AppColors.stateFocusOnDark
                    : low
                    ? AppColors.error
                    : AppColors.orDoux,
                borderRadius: AppRadius.brPill,
              ),
              child: Text(
                percent == null ? '—' : '$percent %',
                maxLines: 1,
                style: AppTypography.labelMedium.copyWith(
                  color: percent == null || low
                      ? AppColors.textOnDark
                      : AppColors.bleuProfond,
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

class _HeaderLabel extends StatelessWidget {
  final CoteGridContext grid;
  final double height;

  const _HeaderLabel({required this.grid, required this.height});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: height,
      padding: _padding,
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: AppColors.blancCasse,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        _label(l10n).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.bleuProfond,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n) {
    if (grid.hasGroupTotals) return l10n.coteColumnAnnual;
    return l10n.coteColumnTotalScope(
      CoteLabels.firstGroupShort(l10n, grid.classe, grid.columns),
    );
  }
}
