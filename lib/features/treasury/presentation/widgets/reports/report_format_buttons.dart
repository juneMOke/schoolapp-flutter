import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/cash_report_opener.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux boutons d'un rapport (A5, B6) : PDF (rouge) et Excel (vert),
/// hauteur 36, rayon 10, fond teinté et bordure à 25 %.
class ReportFormatButtons extends StatefulWidget {
  /// L'id du rapport (`RJ-20261022`…), qui est aussi sa référence imprimée.
  final String reportId;

  /// Le titre de la visionneuse.
  final String title;

  const ReportFormatButtons({
    super.key,
    required this.reportId,
    required this.title,
  });

  @override
  State<ReportFormatButtons> createState() => _ReportFormatButtonsState();
}

class _ReportFormatButtonsState extends State<ReportFormatButtons> {
  /// La visionneuse est ouverte : un second appui n'en ouvre pas une autre.
  var _open = false;

  Future<void> _show(CashReportFormat format) async {
    if (_open) return;
    _open = true;
    await openCashReport(
      context,
      id: widget.reportId,
      title: widget.title,
      format: format,
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FormatButton(
          label: l10n.treasuryReportPdf,
          tooltip: l10n.treasuryReportOpenPdf,
          icon: Icons.description_outlined,
          ink: AppColors.treasuryPdfInk,
          fill: AppColors.treasuryPdfSoft,
          onPressed: () => _show(CashReportFormat.pdf),
        ),
        _FormatButton(
          label: l10n.treasuryReportExcel,
          tooltip: l10n.treasuryReportOpenExcel,
          icon: Icons.grid_on,
          ink: AppColors.treasuryExcelInk,
          fill: AppColors.treasuryExcelSoft,
          onPressed: () => _show(CashReportFormat.xlsx),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color ink;
  final Color fill;
  final VoidCallback? onPressed;

  const _FormatButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.ink,
    required this.fill,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        backgroundColor: fill,
        side: BorderSide(color: ink.withValues(alpha: 0.25)),
        // 36 à l'œil, 48 au doigt : la zone d'appui reste rembourrée.
        minimumSize: const Size(0, AppDimensions.treasuryFormatButtonHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.treasuryFormatButtonRadius,
          ),
        ),
        textStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.lg),
      label: Text(label),
    ),
  );
}
