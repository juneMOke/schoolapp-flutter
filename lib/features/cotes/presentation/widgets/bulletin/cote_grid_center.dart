import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_input.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_labels.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_zone_rows.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_note_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_static_cell.dart';
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
        if (grid.hasGroupTotals) _GroupBand(grid: grid),
        _HeaderRow(grid: grid),
        for (final row in grid.rows)
          switch (row) {
            final CoteRubriqueRow r => _DomainRow(row: r, grid: grid),
            final CoteCourseRow r => _CourseRow(row: r, grid: grid),
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
              text: (column) => _groupPercent(state, column),
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

  String _groupPercent(CoteSaisieReady state, CoteColumn column) {
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
    return percent == null ? '—' : '$percent %';
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
              child: Text(
                text(column),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

/// Portée année : le libellé de chaque groupe au-dessus de ses colonnes.
class _GroupBand extends StatelessWidget {
  final CoteGridContext grid;

  const _GroupBand({required this.grid});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: grid.heights.group,
      color: AppColors.blancCasse,
      child: Row(
        children: [
          for (final periode in grid.classe.periodes)
            SizedBox(
              width: grid.columns
                  .where((c) => c.periodeId == periode.id)
                  .fold<double>(0, (w, c) => w + grid.metrics.widthOf(c)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.bleuArdoise, width: 2),
                  ),
                ),
                child: Text(
                  periode.libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.bleuProfond,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final CoteGridContext grid;

  const _HeaderRow({required this.grid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final decoupage = grid.classe.decoupage;
    return Container(
      height: grid.heights.header,
      decoration: const BoxDecoration(
        color: AppColors.blancCasse,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final column in grid.columns)
            SizedBox(
              width: grid.metrics.widthOf(column),
              child: Tooltip(
                message: CoteLabels.columnLong(l10n, grid.classe, column),
                child: Center(
                  child: _HeaderChip(
                    label: CoteLabels.columnShort(l10n, decoupage, column),
                    column: column,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final CoteColumn column;

  const _HeaderChip({required this.label, required this.column});

  @override
  Widget build(BuildContext context) {
    final (Color? background, Color ink) = switch (column.kind) {
      CoteColumnKind.periode => (null, AppColors.textMuted),
      CoteColumnKind.examen => (
        AppColors.coteExamSurface,
        AppColors.coteExamInk,
      ),
      CoteColumnKind.totalGroupe => (
        AppColors.bleuArdoiseSoft,
        AppColors.bleuProfond,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: background == null
          ? null
          : BoxDecoration(color: background, borderRadius: AppRadius.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (column.locked && column.isInput) ...[
            Icon(Icons.lock_outline_rounded, size: 10, color: ink),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
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
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall.copyWith(
                          color: row.tone.ink,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final CoteCourseRow row;
  final CoteGridContext grid;

  const _CourseRow({required this.row, required this.grid});

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
