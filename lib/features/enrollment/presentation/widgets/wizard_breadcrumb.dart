import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_progress_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_step_dot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fil d'Ariane du stepper d'inscription (PARCOURS 18) : indicateur « Étape N
/// sur M », barre de progression dégradée animée, puis la rangée de pastilles
/// numérotées reliées par des connecteurs.
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
          WizardProgressBar(progress: progress, reduceMotion: reduceMotion),
          const SizedBox(height: AppSpacing.md),
          _StepRow(
            titles: titles,
            currentStep: currentStep,
            reduceMotion: reduceMotion,
            onStepTap: onStepTap,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final bool reduceMotion;
  final ValueChanged<int> onStepTap;

  const _StepRow({
    required this.titles,
    required this.currentStep,
    required this.reduceMotion,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = titles.length;
        final connectorWidth = count > 1
            ? ((constraints.maxWidth - count * WizardStepDot.diameter) /
                      (count - 1))
                  .clamp(12.0, 40.0)
            : 0.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(count, (index) {
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              final canTap = index <= currentStep;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WizardStepDot(
                    index: index,
                    title: titles[index],
                    isCurrent: isCurrent,
                    isDone: isDone,
                    canTap: canTap,
                    reduceMotion: reduceMotion,
                    onTap: () => onStepTap(index),
                  ),
                  if (index < count - 1)
                    Container(
                      width: connectorWidth,
                      height: 2,
                      margin: const EdgeInsets.only(
                        top: WizardStepDot.diameter / 2 - 1,
                      ),
                      color: isDone ? AppColors.vertSavane : AppColors.border,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
