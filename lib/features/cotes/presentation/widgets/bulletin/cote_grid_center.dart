import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_cells.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_row_frame.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_rubrique.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La zone des notes : une ligne par cours, dans l'ordre de Tab.
class CoteGridCenter extends StatelessWidget {
  final CoteGridContext grid;

  const CoteGridCenter({super.key, required this.grid});

  static const _calculator = CoteCalculator();

  @override
  Widget build(BuildContext context) {
    final heights = grid.heights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grid.hasGroupTotals) CoteGroupBand(grid: grid),
        CoteHeaderRow(grid: grid),
        for (final row in grid.rows)
          coteRowReveal(row, switch (row) {
            final CoteRubriqueRow r => CoteRubriqueStrip(row: r, grid: grid),
            final CoteCourseRow r => CoteCourseCells(row: r, grid: grid),
            final CoteSubtotalRow r => CoteSubtotalStrip(
              row: r,
              grid: grid,
              child: _SubtotalCells(row: r, grid: grid),
            ),
          }),
        _cells(
          height: heights.maxima,
          background: AppColors.coteMaxSurface,
          text: (column) => column.isMax
              ? '${_calculator.columnMax(grid.cours, column.source)}'
              : '',
          style: coteMaximaStyle(),
        ),
        CoteStudentBuilder(
          studentId: grid.studentId,
          builder: (context, state) => _cells(
            height: heights.total,
            background: AppColors.bleuProfond,
            text: (column) => column.isMax
                ? ''
                : formatCentis(_sum(state, grid.cours, column.source)),
            style: coteDarkRowStyle(),
          ),
        ),
        if (grid.hasGroupTotals)
          CoteStudentBuilder(
            studentId: grid.studentId,
            builder: (context, state) => _cells(
              height: heights.percent,
              background: AppColors.bleuArdoise,
              text: (column) => column.isMax
                  ? ''
                  : _groupPercent(
                      AppLocalizations.of(context)!,
                      state,
                      column.source,
                    ),
              style: coteDarkRowStyle().copyWith(color: AppColors.orDoux),
            ),
          ),
      ],
    );
  }

  int _sum(
    CoteSaisieReady state,
    Iterable<CoteCours> cours,
    CoteColumn column,
  ) => _calculator.columnSum(
    studentId: grid.studentId,
    cours: cours,
    column: column,
    year: grid.year,
    cells: state.cells,
  );

  String _groupPercent(
    AppLocalizations l10n,
    CoteSaisieReady state,
    CoteColumn column,
  ) {
    if (column.isInput) return '';
    final sources = grid.year.where(
      (c) => c.isInput && c.periodeId == column.periodeId,
    );
    final calc = _calculator.calcEleve(
      studentId: grid.studentId,
      cours: grid.cours,
      columns: sources.toList(growable: false),
      cells: state.cells,
    );
    final percent = calc.pct;
    return percent == null ? '—' : l10n.cotePercent(percent);
  }

  Widget _cells({
    required double height,
    required Color background,
    required String Function(CoteGridColumn) text,
    required TextStyle style,
  }) {
    return Container(
      height: height,
      color: background,
      child: Row(
        children: [
          for (final column in grid.gridColumns)
            SizedBox(
              width: grid.metrics.widthOf(column),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text(column),
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Le sous-total d'une rubrique : ses maxima dans les colonnes Max, ce que
/// l'élève a obtenu dans les autres.
class _SubtotalCells extends StatelessWidget {
  final CoteSubtotalRow row;
  final CoteGridContext grid;

  const _SubtotalCells({required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    final cours = row.rubrique.allCours;
    return CoteStudentBuilder(
      studentId: grid.studentId,
      builder: (context, state) => Row(
        children: [
          for (final column in grid.gridColumns)
            _SubtotalCell(
              column: column,
              row: row,
              grid: grid,
              state: state,
              cours: cours,
            ),
        ],
      ),
    );
  }
}

class _SubtotalCell extends StatelessWidget {
  final CoteGridColumn column;
  final CoteSubtotalRow row;
  final CoteGridContext grid;
  final CoteSaisieReady state;
  final List<CoteCours> cours;

  const _SubtotalCell({
    required this.column,
    required this.row,
    required this.grid,
    required this.state,
    required this.cours,
  });

  static const _calculator = CoteCalculator();

  @override
  Widget build(BuildContext context) {
    final isMax = column.isMax;
    final score = _calculator.columnScore(
      studentId: grid.studentId,
      cours: cours,
      column: column.source,
      year: grid.year,
      cells: state.cells,
    );
    final text = isMax
        ? '${_calculator.columnMax(cours, column.source)}'
        : score.maxFilled == 0
        ? '—'
        : formatCentis(score.total);
    return Container(
      width: grid.metrics.widthOf(column),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMax ? AppColors.coteMaxSurface : null,
        border: coteColumnEdge(column, grid),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AppTypography.labelMedium.copyWith(
            color: isMax
                ? AppColors.bleuArdoise
                : coteScoreInk(score.total, score.maxFilled) ??
                      AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
