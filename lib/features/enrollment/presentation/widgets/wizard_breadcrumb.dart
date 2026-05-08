import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class WizardBreadcrumb extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;

  const WizardBreadcrumb({
    super.key,
    required this.titles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.stepIndicator(
                  currentStep + 1,
                  titles.length,
                ),
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.bleuArdoise),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(titles.length, (index) {
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              final isFuture = index > currentStep;
              final canTap = !isFuture;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MouseRegion(
                    cursor: canTap
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden,
                    child: AnimatedOpacity(
                      duration: AppMotion.fast,
                      curve: AppMotion.outCurve,
                      opacity: isFuture ? 0.55 : 1,
                      child: InkWell(
                        onTap: canTap ? () => onStepTap(index) : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.bleuArdoise
                                : isDone
                                    ? AppColors.bleuArdoise.withValues(alpha: 0.10)
                                    : AppColors.surfaceAlt,
                            borderRadius: const BorderRadius.all(Radius.circular(18)),
                            border: isCurrent
                                ? null
                                : Border.all(
                                    color: isDone
                                        ? AppColors.bleuArdoise.withValues(alpha: 0.14)
                                        : AppColors.border,
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.textOnDark.withValues(alpha: 0.22)
                                      : isDone
                                          ? AppColors.bleuArdoise.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  isDone ? '✓' : '${index + 1}',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent
                                        ? AppColors.textOnDark
                                        : isDone
                                            ? AppColors.bleuArdoise
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                titles[index],
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? AppColors.textOnDark
                                      : isDone
                                          ? AppColors.bleuArdoise
                                          : AppColors.textSecondary.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (index < titles.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
