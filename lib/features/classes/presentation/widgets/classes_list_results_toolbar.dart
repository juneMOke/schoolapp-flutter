import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListResultsToolbar extends StatelessWidget {
  final String title;
  final String subtitle;
  final int resultCount;
  final bool canExport;
  final VoidCallback onExportPressed;

  const ClassesListResultsToolbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.resultCount,
    required this.canExport,
    required this.onExportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final exportButton = _ExportButton(
            canExport: canExport,
            onPressed: onExportPressed,
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );

          final counter = _ResultsCountBadge(count: resultCount);

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    counter,
                    const Spacer(),
                    exportButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              counter,
              const SizedBox(width: AppDimensions.spacingM),
              exportButton,
            ],
          );
        },
      ),
    );
  }
}

class _ResultsCountBadge extends StatelessWidget {
  final int count;

  const _ResultsCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.financeDetailAccentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badge.copyWith(color: AppColors.financeDetailAccent),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool canExport;
  final VoidCallback onPressed;

  const _ExportButton({required this.canExport, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: canExport ? 1 : 0.72,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(9),
        child: Semantics(
          button: true,
          enabled: canExport,
          label: l10n.exportData,
          child: Tooltip(
            message: l10n.exportData,
            child: ElevatedButton.icon(
              onPressed: canExport ? onPressed : null,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.exportData),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: AppColors.surface,
                disabledBackgroundColor: AppColors.classesDisabledBg,
                disabledForegroundColor: AppColors.classesDisabledFg,
                minimumSize: const Size(0, AppDimensions.minTouchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                textStyle: AppTextStyles.action,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
