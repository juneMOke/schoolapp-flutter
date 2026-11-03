import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_row_frame.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_note_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_static_cell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class CoteCourseCells extends StatelessWidget {
  final CoteCourseRow row;
  final CoteGridContext grid;

  const CoteCourseCells({super.key, required this.row, required this.grid});

  @override
  Widget build(BuildContext context) {
    return CoteCourseRowFrame(
      row: row,
      grid: grid,
      child: Row(
        children: [
          for (final column in grid.gridColumns)
            Container(
              width: grid.metrics.widthOf(column),
              decoration: BoxDecoration(
                color: column.isMax ? AppColors.coteMaxSurface : null,
                border: coteColumnEdge(column, grid),
              ),
              padding: column.isMax
                  ? null
                  : const EdgeInsets.symmetric(
                      horizontal: AppDimensions.coteCellHorizontalPadding,
                    ),
              child: column.isMax
                  ? _MaxCell(cours: row.cours, column: column, grid: grid)
                  : _Cell(cours: row.cours, column: column.source, grid: grid),
            ),
        ],
      ),
    );
  }
}

/// Le maximum du cours pour cette colonne : le rappel du bulletin, jamais une
/// saisie. Il n'entre donc pas dans l'ordre de Tab.
class _MaxCell extends StatelessWidget {
  final CoteCours cours;
  final CoteGridColumn column;
  final CoteGridContext grid;

  const _MaxCell({
    required this.cours,
    required this.column,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = column.source;
    final applies = source.appliesTo(cours);
    return CoteStaticCell(
      text: applies ? '${source.maxFor(cours)}' : '—',
      height: grid.heights.cell,
      background: Colors.transparent,
      ink: AppColors.bleuArdoise,
      weight: FontWeight.w800,
      tooltip: applies ? null : l10n.coteCellNoExam,
      semanticLabel: l10n.coteMaxCellSemantics(
        CoteLabels.maxLong(l10n, grid.classe, source),
        cours.branche,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final CoteCours cours;
  final CoteColumn column;
  final CoteGridContext grid;

  const _Cell({required this.cours, required this.column, required this.grid});

  static const _calculator = CoteCalculator();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = grid.heights.cell;
    if (!column.isInput) {
      return CoteStudentBuilder(
        studentId: grid.studentId,
        builder: (context, state) {
          final score = _calculator.columnScore(
            studentId: grid.studentId,
            cours: [cours],
            column: column,
            year: grid.year,
            cells: state.cells,
          );
          return CoteStaticCell(
            text: score.maxFilled == 0 ? '—' : formatCentis(score.total),
            height: height,
            background: AppColors.bleuArdoiseSoft,
            ink:
                coteScoreInk(score.total, score.maxFilled) ??
                AppColors.textMuted,
            decoration: coteScoreMark(score.total, score.maxFilled),
            weight: FontWeight.w700,
            semanticLabel: l10n.coteTotalSemantics(
              CoteLabels.columnLong(l10n, grid.classe, column),
              cours.branche,
            ),
          );
        },
      );
    }
    if (!column.appliesTo(cours)) {
      return CoteStaticCell(
        text: '—',
        height: height,
        background: Colors.transparent,
        ink: AppColors.textMuted,
        tooltip: l10n.coteCellNoExam,
      );
    }
    if (!CoteFocusRegistry.isEditable(cours, column)) {
      return _LockedCell(cours: cours, column: column, grid: grid);
    }
    return CoteNoteCell(
      key: ValueKey('${grid.studentId}|${cours.coursId}|${column.id}'),
      cours: cours,
      column: column,
      registry: grid.registry,
      height: height,
      columnLabel: CoteLabels.columnLong(l10n, grid.classe, column),
      enterMove: grid.enterMove,
      headerHeight: grid.rowsTop,
      dense: grid.metrics.dense,
    );
  }
}

/// Une colonne clôturée : lecture seule. Une cote refusée y reste signalée, sa
/// valeur sous les yeux : la saisie ne peut plus la reprendre.
class _LockedCell extends StatelessWidget {
  final CoteCours cours;
  final CoteColumn column;
  final CoteGridContext grid;

  const _LockedCell({
    required this.cours,
    required this.column,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CoteStudentBuilder(
      studentId: grid.studentId,
      builder: (context, state) {
        final cell = state.cells.cell(grid.studentId, cours.coursId, column.id);
        final value = cell?.displayedValue;
        final rejected = cell?.isRejected ?? false;
        final score = value == null
            ? null
            : coteScoreInk(toCentis(value), column.maxFor(cours) * 100);
        return CoteStaticCell(
          text: value == null ? '—' : formatCote(value),
          height: grid.heights.cell,
          background: rejected
              ? AppColors.coteInvalidSurface
              : AppColors.papier,
          ink: rejected ? AppColors.error : score ?? AppColors.textSecondary,
          decoration: value == null
              ? TextDecoration.none
              : coteScoreMark(toCentis(value), column.maxFor(cours) * 100),
          tooltip: rejected
              ? CoteLabels.rejection(l10n, cell?.rejectionReason)
              : l10n.coteCellLocked,
          semanticLabel: l10n.coteCellSemantics(
            cours.branche,
            CoteLabels.columnLong(l10n, grid.classe, column),
            '${column.maxFor(cours)}',
          ),
        );
      },
    );
  }
}
