import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/data/xlsx/xlsx_workbook.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/xlsx_sheet_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'aperçu d'un classeur (A6), à la manière d'un tableur : la feuille
/// centrée avec ses lettres de colonnes et ses numéros de lignes, les
/// onglets des feuilles en bas.
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
    return ColoredBox(
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                : XlsxSheetGrid(key: ValueKey(_sheet), sheet: sheet),
          ),
          _SheetTabs(
            names: [for (final s in sheets) s.name],
            selected: _sheet,
            onSelected: (index) => setState(() => _sheet = index),
            label: l10n.treasuryXlsxSheets,
          ),
        ],
      ),
    );
  }
}

/// Les onglets des feuilles, en bas, comme dans un tableur.
class _SheetTabs extends StatelessWidget {
  final List<String> names;
  final int selected;
  final ValueChanged<int> onSelected;
  final String label;

  const _SheetTabs({
    required this.names,
    required this.selected,
    required this.onSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (i, name) in names.indexed)
              Semantics(
                selected: i == selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? AppColors.surfaceRaised : null,
                      border: i == selected
                          ? const Border(
                              bottom: BorderSide(
                                color: AppColors.treasuryExcelInk,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      name,
                      style: AppTypography.labelMedium.copyWith(
                        color: i == selected
                            ? AppColors.treasuryExcelInk
                            : AppColors.textSecondary,
                        fontWeight: i == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
