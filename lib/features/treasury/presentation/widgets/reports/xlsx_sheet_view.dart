import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_workbook.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aperçu d'un classeur (A6) : un onglet par feuille, puis la grille. Les
/// lignes se construisent à l'écran seulement : l'onglet « Données » d'un
/// rapport annuel compte des milliers de mouvements.
class XlsxWorkbookView extends StatefulWidget {
  final XlsxWorkbook workbook;

  const XlsxWorkbookView({super.key, required this.workbook});

  @override
  State<XlsxWorkbookView> createState() => _XlsxWorkbookViewState();
}

class _XlsxWorkbookViewState extends State<XlsxWorkbookView> {
  var _sheet = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheets = widget.workbook.sheets;
    final sheet = sheets[_sheet.clamp(0, sheets.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sheets.length > 1)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SegmentedTabFilter<int>(
                style: TreasuryTones.filter,
                semanticsLabel: l10n.treasuryXlsxSheets,
                selected: _sheet,
                onSelected: (index) => setState(() => _sheet = index),
                wrap: true,
                options: [
                  for (final (i, s) in sheets.indexed)
                    SegmentedTabOption(
                      label: s.name,
                      value: i,
                      icon: Icons.grid_on,
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: sheet.rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.treasuryXlsxEmptySheet,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : _SheetGrid(key: ValueKey(_sheet), sheet: sheet),
        ),
      ],
    );
  }
}

class _SheetGrid extends StatefulWidget {
  final XlsxSheet sheet;

  const _SheetGrid({super.key, required this.sheet});

  @override
  State<_SheetGrid> createState() => _SheetGridState();
}

class _SheetGridState extends State<_SheetGrid> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  late final List<double> _widths = _measure(widget.sheet);

  static const double _charWidth = 7.2;
  static const int _sampleRows = 200;

  /// Une largeur par colonne, d'après son texte le plus long sur les
  /// premières lignes, bornée.
  static List<double> _measure(XlsxSheet sheet) {
    final widths = List<double>.filled(
      sheet.columnCount,
      AppDimensions.treasuryXlsxColumnMin,
    );
    for (final row in sheet.rows.take(_sampleRows)) {
      for (final (i, cell) in row.indexed) {
        final w = cell.text.length * _charWidth + 2 * AppSpacing.sm;
        widths[i] = math.max(widths[i], w);
      }
    }
    return [
      for (final w in widths)
        w.clamp(
          AppDimensions.treasuryXlsxColumnMin,
          AppDimensions.treasuryXlsxColumnMax,
        ),
    ];
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _widths.fold<double>(0, (a, b) => a + b);
    return Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontal,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: total,
          child: Scrollbar(
            controller: _vertical,
            child: ListView.builder(
              controller: _vertical,
              itemCount: widget.sheet.rows.length,
              itemExtent: AppDimensions.treasuryXlsxRowHeight,
              itemBuilder: (context, index) => _row(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int index) {
    final row = widget.sheet.rows[index];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isOdd ? AppColors.treasuryTableZebra : null,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final (i, cell) in row.indexed)
            Container(
              width: _widths[i],
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: cell.numeric
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                cell.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: cell.bold ? FontWeight.w700 : FontWeight.w400,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
