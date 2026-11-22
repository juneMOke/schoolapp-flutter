import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux boutons d'export du tableau de bord (I12, O3) : PDF (rouge) et
/// Excel (vert), aux jetons des rapports de la Trésorerie — hauteur 36 à
/// l'œil, 48 au doigt.
///
/// Ils ouvrent la visionneuse sur [query] (la recherche ne restreint pas
/// l'export, Q5). Inactifs quand [enabled] est faux, avec [disabledReason]
/// en info-bulle (hors ligne, onglet vide).
class RecoveryExportButtons extends StatelessWidget {
  final RecoveryStudentsQuery query;

  /// Le titre R10 de la liste, repris par la visionneuse.
  final String title;
  final bool enabled;
  final String? disabledReason;

  const RecoveryExportButtons({
    super.key,
    required this.query,
    required this.title,
    this.enabled = true,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) => RecoveryFormatButtons(
    enabled: enabled,
    disabledReason: disabledReason,
    onSelected: (format) =>
        openRecoveryExport(context, query: query, format: format, title: title),
  );
}

/// L'apparence des deux boutons PDF · Excel, sans l'ouverture : [onSelected]
/// reçoit le format et rend la main quand la visionneuse se ferme. Un second
/// appui pendant qu'elle est ouverte n'en ouvre pas une autre (I19).
class RecoveryFormatButtons extends StatefulWidget {
  final Future<void> Function(RecoveryExportFormat format) onSelected;
  final bool enabled;
  final String? disabledReason;

  const RecoveryFormatButtons({
    super.key,
    required this.onSelected,
    this.enabled = true,
    this.disabledReason,
  });

  @override
  State<RecoveryFormatButtons> createState() => _RecoveryFormatButtonsState();
}

class _RecoveryFormatButtonsState extends State<RecoveryFormatButtons> {
  /// La visionneuse est ouverte : un second appui n'en ouvre pas une autre.
  var _open = false;

  Future<void> _show(RecoveryExportFormat format) async {
    if (_open) return;
    _open = true;
    try {
      await widget.onSelected(format);
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = widget.enabled ? null : widget.disabledReason;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _ExportButton(
          label: l10n.treasuryReportPdf,
          tooltip: reason ?? l10n.treasuryReportOpenPdf,
          icon: Icons.description_outlined,
          ink: AppColors.treasuryPdfInk,
          fill: AppColors.treasuryPdfSoft,
          onPressed: widget.enabled
              ? () => _show(RecoveryExportFormat.pdf)
              : null,
        ),
        _ExportButton(
          label: l10n.treasuryReportExcel,
          tooltip: reason ?? l10n.treasuryReportOpenExcel,
          icon: Icons.grid_on,
          ink: AppColors.treasuryExcelInk,
          fill: AppColors.treasuryExcelSoft,
          onPressed: widget.enabled
              ? () => _show(RecoveryExportFormat.xlsx)
              : null,
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color ink;
  final Color fill;
  final VoidCallback? onPressed;

  const _ExportButton({
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
        disabledForegroundColor: ink.withValues(alpha: 0.45),
        disabledBackgroundColor: fill.withValues(alpha: 0.6),
        side: BorderSide(
          color: ink.withValues(alpha: onPressed == null ? 0.12 : 0.25),
        ),
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
