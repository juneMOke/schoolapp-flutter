import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.stepIndicator(currentStep + 1, titles.length),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.terreCuite,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              const stepCircleDiameter = 36.0; // Pastille 36×36
              const stepLabelWidth = 72.0; // Espace pour label sous pastille
              final connectorWidth = titles.length > 1
                  ? (constraints.maxWidth -
                            (titles.length * stepCircleDiameter)) /
                        (titles.length - 1)
                  : 0.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(titles.length, (index) {
                    final isDone = index < currentStep;
                    final isCurrent = index == currentStep;
                    final isFuture = index > currentStep;
                    final canTap = !isFuture;

                    final circleColor = isCurrent
                        ? AppColors.terreCuite
                        : isDone
                        ? AppColors.vertSavane
                        : AppColors.surfaceAlt;
                    final borderColor = isCurrent
                        ? AppColors.terreCuite
                        : isDone
                        ? AppColors.vertSavane
                        : AppColors.border;

                    return Row(
                      children: [
                        Column(
                          children: [
                            MouseRegion(
                              cursor: canTap
                                  ? SystemMouseCursors.click
                                  : SystemMouseCursors.forbidden,
                              child: InkWell(
                                onTap: canTap ? () => onStepTap(index) : null,
                                borderRadius: BorderRadius.circular(18),
                                child: AnimatedContainer(
                                  duration: AppMotion.fast,
                                  width: stepCircleDiameter,
                                  height: stepCircleDiameter,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: circleColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: AppColors.terreCuite
                                                  .withValues(alpha: 0.40),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isDone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: AppColors.textOnDark,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent
                                                    ? AppColors.textOnDark
                                                    : AppColors.textSecondary,
                                              ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: stepLabelWidth,
                              child: Text(
                                titles[index],
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isCurrent
                                      ? AppColors.terreCuite
                                      : isDone
                                      ? AppColors.vertSavane
                                      : AppColors.textMuted,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (index < titles.length - 1)
                          Container(
                            width: connectorWidth.clamp(12, 40),
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 22),
                            color: isDone
                                ? AppColors.vertSavane
                                : AppColors.border,
                          ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
