import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_progress_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_step_dot.dart';

/// Barre du stepper d'inscription (PARCOURS 18) : bande pleine largeur collée
/// sous l'AppBar — barre de progression dégradée puis la rangée de steps
/// (chip + connecteurs + « ÉTAPE N » / description) répartis de bout en bout.
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    final count = titles.length;

    // Steps répartis à parts égales (Expanded) pour occuper toute la largeur ;
    // les connecteurs relient les chips de bout en bout.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(count, (index) {
        final isDone = index < currentStep;
        final isCurrent = index == currentStep;
        final canTap = index <= currentStep;

        return Expanded(
          child: WizardStepDot(
            index: index,
            title: titles[index],
            isCurrent: isCurrent,
            isDone: isDone,
            canTap: canTap,
            reduceMotion: reduceMotion,
            onTap: () => onStepTap(index),
            isFirst: index == 0,
            isLast: index == count - 1,
            leftConnectorActive: index <= currentStep,
            rightConnectorActive: index < currentStep,
          ),
        );
      }),
    );
  }
}
