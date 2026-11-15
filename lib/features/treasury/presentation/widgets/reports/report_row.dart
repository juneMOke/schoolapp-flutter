import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_format_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les colonnes du tableau des rapports (A5) : RAPPORT (le reste, 220 au
/// moins) · PÉRIODE COUVERTE · STATUT · CONSULTER (à droite).
abstract final class ReportColumns {
  static const List<double?> widths = [
    null,
    AppDimensions.treasuryReportPeriodWidth,
    AppDimensions.treasuryReportStatusWidth,
    AppDimensions.treasuryReportConsultWidth,
  ];

  static const double minWidth =
      AppDimensions.treasuryReportTitleMinWidth +
      AppDimensions.treasuryReportPeriodWidth +
      AppDimensions.treasuryReportStatusWidth +
      AppDimensions.treasuryReportConsultWidth +
      2 * AppSpacing.sm;

  static List<String> headers(AppLocalizations l10n) => [
    l10n.treasuryReportColReport,
    l10n.treasuryReportColPeriod,
    l10n.treasuryReportColStatus,
    l10n.treasuryReportColConsult,
  ];

  static IconData iconOf(CashReportKind kind) => switch (kind) {
    CashReportKind.daily => Icons.schedule,
    CashReportKind.weekly => Icons.calendar_today_outlined,
    CashReportKind.monthly => Icons.date_range,
    CashReportKind.yearly => Icons.event_available,
    CashReportKind.period => Icons.filter_alt_outlined,
  };
}

/// Une ligne de rapport. Toucher la ligne ouvre le PDF ; les deux boutons
/// ouvrent PDF ou Excel.
EteeloColumnTableRow reportRow(
  BuildContext context, {
  required CashReport report,
  required bool isToday,
  required VoidCallback onOpen,
}) {
  final l10n = AppLocalizations.of(context)!;
  final period = report.from == report.to
      ? l10n.treasuryReportDay(report.from)
      : l10n.treasuryRangeLabel(report.from, report.to);
  return EteeloColumnTableRow(
    widths: ReportColumns.widths,
    onTap: onOpen,
    cells: [
      _TitleCell(report: report, isToday: isToday),
      Text(
        report.inProgress && report.kind != CashReportKind.daily
            ? '$period ${l10n.treasuryReportUntilToday}'
            : period,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _StatusCell(report: report),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ReportFormatButtons(reportId: report.id, title: report.title),
      ),
    ],
  );
}

class _TitleCell extends StatelessWidget {
  final CashReport report;
  final bool isToday;

  const _TitleCell({required this.report, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final running = !report.isFinal;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppDimensions.treasuryReportRowMinHeight - 2 * AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.treasuryReportPictogram,
            height: AppDimensions.treasuryReportPictogram,
            decoration: BoxDecoration(
              color: running
                  ? AppColors.treasuryPendingSoft
                  : AppColors.treasuryOpeningSoft,
              borderRadius: BorderRadius.circular(
                AppDimensions.treasuryFormatButtonRadius,
              ),
            ),
            child: Icon(
              ReportColumns.iconOf(report.kind),
              size: AppSpacing.lg,
              color: AppColors.terreCuite,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall,
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      [
                        report.id,
                        for (final c in report.currencies) c.code,
                      ].join(' · '),
                      style: AppTextStyles.codeMuted,
                    ),
                    if (isToday)
                      _Badge(
                        label: l10n.treasuryToday,
                        ink: AppColors.surfaceRaised,
                        fill: AppColors.terreCuite,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final CashReport report;

  const _StatusCell({required this.report});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provisional = !report.isFinal;
    final tone = provisional ? TreasuryTones.pending : TreasuryTones.inflow;
    final status = _Badge(
      icon: provisional ? Icons.schedule : Icons.check,
      label: !provisional
          ? l10n.treasuryReportFinal
          : report.kind == CashReportKind.daily
          ? l10n.treasuryReportProvisionalDay
          : l10n.treasuryReportProvisionalPeriod,
      ink: tone.ink,
      fill: tone.soft,
      border: tone.border,
    );
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (provisional)
          Tooltip(message: l10n.treasuryReportProvisionalHint, child: status)
        else
          status,
        if (report.archived)
          Tooltip(
            message: l10n.treasuryReportArchivedHint,
            child: _Badge(
              icon: Icons.inventory_2_outlined,
              label: l10n.treasuryReportArchived,
              ink: AppColors.textSecondary,
              fill: AppColors.surfaceAlt,
              border: AppColors.border,
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color ink;
  final Color fill;
  final Color? border;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.ink,
    required this.fill,
    this.border,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    final border = this.border;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: fill,
        border: border == null ? null : Border.all(color: border),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
