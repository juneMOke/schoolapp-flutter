import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_format_buttons.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre de rapport de l'écran Clôture (B6). Le journalier reste
/// **verrouillé** tant que la journée n'est pas clôturée (R12, règle d'écran :
/// le serveur, lui, servirait le fichier en provisoire) ; l'hebdomadaire et
/// le mensuel sont toujours disponibles.
class ClosingReportBar extends StatelessWidget {
  /// « Rapport journalier », « Rapport hebdomadaire »…
  final String label;

  /// Le titre de la période, pour la ligne d'aide et la visionneuse.
  final String title;
  final String reportId;

  /// Caisses encore ouvertes : la barre dit ce qu'il reste à clôturer, sans
  /// bouton. `0` : le rapport est disponible.
  final int remainingRegisters;

  const ClosingReportBar({
    super.key,
    required this.label,
    required this.title,
    required this.reportId,
    this.remainingRegisters = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locked = remainingRegisters > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locked ? Icons.lock_outline : Icons.description_outlined,
                color: locked ? AppColors.textSecondary : AppColors.terreCuite,
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.titleSmall),
                    Text(
                      locked
                          ? (remainingRegisters == 1
                                ? l10n.treasuryReportLockedLast
                                : l10n.treasuryReportLockedAll)
                          : '$title · $reportId',
                      style: AppTypography.bodySmall.copyWith(
                        color: locked
                            ? AppColors.financeCrossedAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (locked)
            Text(
              l10n.treasuryReportAfterClose,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ReportFormatButtons(reportId: reportId, title: title),
        ],
      ),
    );
  }
}
