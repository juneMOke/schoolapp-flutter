import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_cells.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_header.dart';
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
          switch (row) {
            final CoteRubriqueRow r => _DomainRow(row: r, grid: grid),
            final CoteCourseRow r => CoteCourseCells(row: r, grid: grid),
          },
        _cells(
          height: heights.maxima,
          background: AppColors.blancCasse,
          text: (column) => '${_calculator.columnMax(grid.cours, column)}',
          style: coteMaximaStyle(),
        ),
        CoteStudentBuilder(
          studentId: grid.studentId,
          builder: (context, state) => _cells(
            height: heights.total,
            background: AppColors.bleuProfond,
            text: (column) => formatCentis(_sum(state, grid.cours, column)),
            style: coteDarkRowStyle(),
          ),
        ),
        if (grid.hasGroupTotals)
          CoteStudentBuilder(
            studentId: grid.studentId,
            builder: (context, state) => _cells(
              height: heights.percent,
              background: AppColors.bleuArdoise,
              text: (column) =>
                  _groupPercent(AppLocalizations.of(context)!, state, column),
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
    required String Function(CoteColumn) text,
    required TextStyle style,
  }) {
    return Container(
      height: height,
      color: background,
      child: Row(
        children: [
          for (final column in grid.columns)
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

class _DomainRow extends StatelessWidget {
  final CoteRubriqueRow row;
  final CoteGridContext grid;

  const _DomainRow({required this.row, required this.grid});

  static const _calculator = CoteCalculator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.domain,
      color: row.tone.soft,
      child: !row.rubrique.produitSousTotal
          ? null
          : CoteStudentBuilder(
              studentId: grid.studentId,
              builder: (context, state) => Row(
                children: [
                  for (final column in grid.columns)
                    SizedBox(
                      width: grid.metrics.widthOf(column),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatCentis(
                            _calculator.columnSum(
                              studentId: grid.studentId,
                              cours: row.rubrique.allCours,
                              column: column,
                              year: grid.year,
                              cells: state.cells,
                            ),
                          ),
                          maxLines: 1,
                          softWrap: false,
                          style: AppTypography.labelSmall.copyWith(
                            color: row.tone.ink,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
