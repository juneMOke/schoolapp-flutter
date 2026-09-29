import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_progress_bar.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_dot.dart';

/// Barre de stepper d'assistant (née avec le parcours d'inscription,
/// PARCOURS 18) : bande pleine largeur collée
/// sous l'AppBar — barre de progression dégradée puis la rangée de steps
/// (chip + connecteurs + « ÉTAPE N » / description) répartis de bout en bout.
///
/// En [compact], la bande garde son fond et son liseré mais se réduit à sa
/// seule progression : une dizaine de dp au lieu d'une centaine (cf.
/// `WizardChromeDensity`).
class WizardBreadcrumb extends StatelessWidget {
  final List<String> titles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;

  /// Barre réduite à sa progression, quand la hauteur disponible ne permet plus
  /// d'afficher les steps sans manger le champ en cours de saisie.
  final bool compact;

  /// Qui est franchi et atteignable. `null` : le régime linéaire du parcours
  /// d'inscription (retour libre, saut avant interdit), calculé depuis
  /// [currentStep]. Un assistant qui rouvre ses étapes en consultation passe
  /// sa propre progression.
  final WizardStepProgression? progression;

  /// Étapes à montrer en erreur (après une tentative).
  final Set<int> errorSteps;

  const WizardBreadcrumb({
    super.key,
    required this.titles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
    this.compact = false,
    this.progression,
    this.errorSteps = const <int>{},
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final progressBar = WizardProgressBar(
      progress: progress,
      reduceMotion: reduceMotion,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: compact
          ? progressBar
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                progressBar,
                const SizedBox(height: AppSpacing.md),
                _StepRow(
                  titles: titles,
                  progression:
                      progression ??
                      WizardStepProgression.linear(
                        stepCount: titles.length,
                        currentStep: currentStep,
                      ),
                  errorSteps: errorSteps,
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
  final WizardStepProgression progression;
  final Set<int> errorSteps;
  final bool reduceMotion;
  final ValueChanged<int> onStepTap;

  const _StepRow({
    required this.titles,
    required this.progression,
    required this.errorSteps,
    required this.reduceMotion,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = titles.length;
    final currentStep = progression.currentStep;

    // Steps répartis à parts égales (Expanded) pour occuper toute la largeur ;
    // les connecteurs relient les chips de bout en bout.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List<Widget>.generate(count, (index) {
        final status = progression.statusAt(index);

        return Expanded(
          child: WizardStepDot(
            index: index,
            title: titles[index],
            isCurrent: status.isCurrent,
            isDone: status.isDone,
            canTap: status.canTap,
            reduceMotion: reduceMotion,
            onTap: () => onStepTap(index),
            isFirst: index == 0,
            isLast: index == count - 1,
            leftConnectorActive: index <= currentStep,
            rightConnectorActive: index < currentStep,
            hasError: errorSteps.contains(index),
          ),
        );
      }),
    );
  }
}
