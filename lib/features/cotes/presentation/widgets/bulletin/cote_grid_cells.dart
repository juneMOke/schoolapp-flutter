import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
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
    return Container(
      height: grid.heights.course,
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final column in grid.columns)
            SizedBox(
              width: grid.metrics.widthOf(column),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.coteCellHorizontalPadding,
                ),
                child: _Cell(cours: row.cours, column: column, grid: grid),
              ),
            ),
        ],
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
        builder: (context, state) => CoteStaticCell(
          text: formatCentis(
            _calculator.columnSum(
              studentId: grid.studentId,
              cours: [cours],
              column: column,
              year: grid.year,
              cells: state.cells,
            ),
          ),
          height: height,
          background: AppColors.bleuArdoiseSoft,
          ink: AppColors.bleuProfond,
          weight: FontWeight.w700,
          semanticLabel: l10n.coteTotalSemantics(
            CoteLabels.columnLong(l10n, grid.classe, column),
            cours.branche,
          ),
        ),
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
        return CoteStaticCell(
          text: value == null ? '—' : formatCote(value),
          height: grid.heights.cell,
          background: rejected
              ? AppColors.coteInvalidSurface
              : AppColors.papier,
          ink: rejected ? AppColors.error : AppColors.textSecondary,
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
