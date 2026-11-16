import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_workbook.dart';

/// Une feuille : la grille, ses lettres de colonnes et ses numéros de
/// lignes, centrée quand elle tient. Les lignes se construisent à l'écran
/// seulement : l'onglet « Données » d'un rapport annuel compte des milliers
/// de mouvements.
class XlsxSheetGrid extends StatefulWidget {
  final XlsxSheet sheet;

  const XlsxSheetGrid({super.key, required this.sheet});

  @override
  State<XlsxSheetGrid> createState() => _XlsxSheetGridState();
}

class _XlsxSheetGridState extends State<XlsxSheetGrid> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  late final List<double> _widths = XlsxColumnWidths.of(widget.sheet);

  /// En deçà, le texte deviendrait trop petit : on défile de côté.
  static const double _minFitScale = 0.75;

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        AppDimensions.treasuryXlsxGutter +
        _widths.fold<double>(0, (a, b) => a + b);
    final sheet = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          XlsxGridRow.letters(_widths),
          Expanded(
            child: Scrollbar(
              controller: _vertical,
              child: ListView.builder(
                controller: _vertical,
                itemCount: widget.sheet.rows.length,
                itemBuilder: (context, index) => XlsxGridRow(
                  number: widget.sheet.firstRow + index,
                  cells: widget.sheet.rows[index],
                  widths: _widths,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth - 2 * AppSpacing.md;
        // La feuille tient : centrée, sans défilement de côté.
        if (total <= room) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: SizedBox(width: total, child: sheet),
            ),
          );
        }
        // Elle dépasse de peu : réduite pour tenir entière, comme « ajuster à
        // la largeur » d'un tableur.
        final scale = room / total;
        if (scale >= _minFitScale) {
          final height = constraints.maxHeight - 2 * AppSpacing.md;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: total,
                  height: height / scale,
                  child: sheet,
                ),
              ),
            ),
          );
        }
        return Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(width: total, child: sheet),
          ),
        );
      },
    );
  }
}

/// La largeur de chaque colonne : celle que pose la feuille, élargie pour
/// toute cellule qui ne peut pas déborder (un nombre, une date, un titre
/// coloré, un texte dont la voisine est occupée). Un texte suivi d'une case
/// vide y déborde, comme dans un tableur.
abstract final class XlsxColumnWidths {
  static const double _charWidth = 8.3;
  static const double _boldCharWidth = 8.6;

  /// Une unité de largeur d'Excel vaut à peu près un caractère.
  static const double _excelUnit = 7.5;
  static const int _sampleRows = 200;

  static List<double> of(XlsxSheet sheet) {
    final needed = List<double>.filled(sheet.columnCount, 0);
    final used = List<bool>.filled(sheet.columnCount, false);
    for (final row in sheet.rows.take(_sampleRows)) {
      for (final (i, cell) in row.indexed) {
        if (cell.text.isEmpty || cell.span != 1) continue;
        used[i] = true;
        // Un texte peut déborder sur une case vide à sa droite ; sinon (un
        // nombre, une date, un titre coloré, un voisin occupé) sa colonne
        // doit le contenir.
        final canSpill =
            !cell.numeric &&
            cell.fill == null &&
            (i + 1 >= row.length || row[i + 1].isBlank);
        if (canSpill) continue;
        final w =
            cell.text.length * (cell.bold ? _boldCharWidth : _charWidth) +
            2 * AppSpacing.sm;
        needed[i] = math.max(needed[i], w);
      }
    }
    return [
      for (var i = 0; i < sheet.columnCount; i++)
        () {
          final excel = i < sheet.widths.length ? sheet.widths[i] : null;
          final posed = excel == null
              ? (used[i] ? AppDimensions.treasuryXlsxColumnMin : 0.0)
              : excel * _excelUnit;
          return math
              .max(posed, needed[i])
              .clamp(
                AppDimensions.treasuryXlsxMargin,
                AppDimensions.treasuryXlsxColumnMax,
              );
        }(),
    ];
  }
}

/// Une ligne de la grille : son numéro, puis ses cellules. Un texte aligné
/// à gauche s'étale sur les cases vides qui le suivent ; une cellule
/// fusionnée couvre ses colonnes.
class XlsxGridRow extends StatelessWidget {
  final String label;
  final List<XlsxCell> cells;
  final List<double> widths;
  final bool header;

  // ignore: prefer_const_constructors_in_immutables
  XlsxGridRow({
    super.key,
    required int number,
    required this.cells,
    required this.widths,
  }) : label = '$number',
       header = false;

  /// La ligne des lettres de colonnes : A, B, C…
  XlsxGridRow.letters(this.widths, {super.key})
    : label = '',
      header = true,
      cells = [for (var i = 0; i < widths.length; i++) XlsxCell(letter(i))];

  /// 0 → A, 25 → Z, 26 → AA.
  static String letter(int index) {
    var n = index + 1;
    var out = '';
    while (n > 0) {
      out = String.fromCharCode(65 + (n - 1) % 26) + out;
      n = (n - 1) ~/ 26;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _headerCell(label, AppDimensions.treasuryXlsxGutter),
    ];
    for (var i = 0; i < cells.length && i < widths.length; i++) {
      final cell = cells[i];
      if (cell.span == 0) continue;
      if (header) {
        children.add(_headerCell(cell.text, widths[i]));
        continue;
      }
      var end = math.min<int>(i + math.max<int>(cell.span, 1), widths.length);
      final spills =
          cell.span == 1 &&
          cell.text.isNotEmpty &&
          !cell.numeric &&
          cell.align != XlsxAlign.center &&
          cell.align != XlsxAlign.end;
      if (spills) {
        while (end < cells.length &&
            end < widths.length &&
            cells[end].isBlank &&
            cells[end].span == 1) {
          end++;
        }
      }
      final width = widths.sublist(i, end).fold<double>(0, (a, b) => a + b);
      children.add(_cell(cell, width));
      i = end - 1;
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _headerCell(String text, double width) => Container(
    width: width,
    constraints: const BoxConstraints(
      minHeight: AppDimensions.treasuryXlsxHeaderHeight,
    ),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.surfaceAlt,
      border: Border(
        right: BorderSide(color: AppColors.border),
        bottom: BorderSide(color: AppColors.border),
      ),
    ),
    child: Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _cell(XlsxCell cell, double width) {
    final fill = cell.fill;
    final ink = cell.ink;
    final align = switch (cell.align) {
      XlsxAlign.center => Alignment.center,
      XlsxAlign.end => Alignment.centerRight,
      XlsxAlign.start => Alignment.centerLeft,
      null => cell.numeric ? Alignment.centerRight : Alignment.centerLeft,
    };
    return Container(
      width: width,
      constraints: const BoxConstraints(
        minHeight: AppDimensions.treasuryXlsxRowHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      alignment: align,
      decoration: BoxDecoration(
        color: fill == null ? null : Color(fill),
        border: const Border(
          right: BorderSide(color: AppColors.treasuryChartGrid),
          bottom: BorderSide(color: AppColors.treasuryChartGrid),
        ),
      ),
      child: Text(
        cell.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: switch (align) {
          Alignment.center => TextAlign.center,
          Alignment.centerRight => TextAlign.right,
          _ => TextAlign.left,
        },
        style: AppTypography.bodySmall.copyWith(
          color: ink == null ? AppColors.textPrimary : Color(ink),
          fontWeight: cell.bold ? FontWeight.w700 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
