import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_format_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de rapport (A5) : le titre tel qu'imprimé, sa référence et ses
/// devises, le badge « Aujourd'hui », le statut (R8), puis PDF et Excel.
/// Les éléments passent à la ligne sur téléphone plutôt que de déborder.
class ReportRow extends StatelessWidget {
  final CashReport report;
  final bool isToday;

  const ReportRow({super.key, required this.report, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provisional = !report.isFinal;
    final statusLabel = !provisional
        ? l10n.treasuryReportFinal
        : report.kind == CashReportKind.daily
        ? l10n.treasuryReportProvisionalDay
        : l10n.treasuryReportProvisionalPeriod;
    final ink = provisional
        ? AppColors.financeCrossedAccent
        : AppColors.success;
    return ColoredBox(
      color: AppColors.surfaceRaised,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(report.title, style: AppTypography.titleSmall),
                    if (isToday)
                      _Badge(
                        label: l10n.treasuryToday,
                        ink: AppColors.terreCuite,
                      ),
                  ],
                ),
                Text(
                  [
                    report.id,
                    for (final c in report.currencies) c.code,
                  ].join(' · '),
                  style: AppTextStyles.codeMuted,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (report.archived)
                  Tooltip(
                    message: l10n.treasuryReportArchivedHint,
                    child: _Badge(
                      label: l10n.treasuryReportArchived,
                      ink: AppColors.textSecondary,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                if (provisional)
                  Tooltip(
                    message: l10n.treasuryReportProvisionalHint,
                    child: _Badge(
                      label: statusLabel,
                      ink: ink,
                      icon: Icons.schedule,
                    ),
                  )
                else
                  _Badge(
                    label: statusLabel,
                    ink: ink,
                    icon: Icons.check_circle_outline,
                  ),
                ReportFormatButtons(reportId: report.id, title: report.title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color ink;
  final IconData? icon;

  const _Badge({required this.label, required this.ink, this.icon});

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: AppSpacing.md, color: ink),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
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
