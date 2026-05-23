import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListResultsToolbar extends StatelessWidget {
  final String summary;
  final bool canExport;
  final VoidCallback onExportPressed;

  const ClassesListResultsToolbar({
    super.key,
    required this.summary,
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
                summary,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
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
              exportButton,
            ],
          );
        },
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
          label: l10n.classesListExportPdf,
          child: Tooltip(
            message: l10n.classesListExportPdf,
            child: OutlinedButton.icon(
              onPressed: canExport ? onPressed : null,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.classesListExportPdf),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bleuArdoise,
                disabledForegroundColor: AppColors.classesDisabledFg,
                side: BorderSide(
                  color: canExport
                      ? AppColors.bleuArdoise.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
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
