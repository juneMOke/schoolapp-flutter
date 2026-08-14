import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_chrome_density.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/step_page_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/wizard_breadcrumb.dart';

/// Disposition du parcours d'inscription : barre d'étapes en tête, carte
/// d'étape défilante au centre, pied d'actions ancré en bas (PARCOURS 18/21).
///
/// La barre et le pied sont **fixes** : leur hauteur ne dépend pas de la place
/// disponible. Le clavier logiciel, lui, retire sa hauteur au body — sur un
/// téléphone en paysage il ne laissait plus que ~130 dp pour ~175 dp de chrome,
/// et la colonne débordait dès la première saisie. Le chrome se raréfie donc
/// par paliers de hauteur (`WizardChromeDensity`) : la barre passe à sa seule
/// progression, puis disparaît, et les marges se resserrent — la carte d'étape
/// garde toujours ce qui reste.
class EnrollmentStepperLayout extends StatelessWidget {
  final List<String> stepTitles;
  final int currentStep;
  final double progress;
  final ValueChanged<int> onStepTap;
  final String stepTitle;
  final String stepSubtitle;
  final String stepEyebrow;
  final Color stepAccentColor;
  final IconData stepIcon;
  final Widget stepContent;
  final Widget? stepBanner;
  final Widget controls;

  const EnrollmentStepperLayout({
    super.key,
    required this.stepTitles,
    required this.currentStep,
    required this.progress,
    required this.onStepTap,
    required this.stepTitle,
    required this.stepSubtitle,
    required this.stepEyebrow,
    required this.stepAccentColor,
    required this.stepIcon,
    required this.stepContent,
    required this.controls,
    this.stepBanner,
  });

  // Largeur max de la carte d'étape : large, bornée sur très grand écran (au-delà
  // elle reste centrée). Les champs s'organisent en 1/2/3 colonnes selon la
  // largeur disponible (voir WizardFieldsGrid) → carte large, hauteur modérée.
  static const double _stepCardMaxWidth = 1100;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = WizardChromeDensity.forHeight(constraints.maxHeight);
        final roomy = density.usesFullSpacing;

        return Padding(
          // Barre de steps + pied à pleine largeur (collés aux bords) ; seule
          // une marge basse subsiste — et elle cède la place la première quand
          // la hauteur manque.
          padding: EdgeInsets.only(bottom: roomy ? AppTheme.defaultPadding : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (density.showsBreadcrumb) ...[
                WizardBreadcrumb(
                  titles: stepTitles,
                  currentStep: currentStep,
                  progress: progress,
                  onStepTap: onStepTap,
                  compact: density.usesCompactBreadcrumb,
                ),
                SizedBox(height: roomy ? AppSpacing.md : AppSpacing.xs),
              ],
              Expanded(
                // Carte d'étape large, centrée horizontalement, avec de
                // l'espace tout autour. Défile si son contenu dépasse la
                // hauteur disponible.
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.defaultPadding,
                    vertical: roomy ? AppTheme.defaultPadding : AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _stepCardMaxWidth,
                      ),
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : AppMotion.stepIn,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          if (reduceMotion) return child;
                          // etStepIn : fondu + glissement translateY 10 → 0.
                          return FadeTransition(
                            opacity: animation,
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, inner) => Transform.translate(
                                offset: Offset(0, (1 - animation.value) * 10),
                                child: inner,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: StepPageCard(
                          key: ValueKey(currentStep),
                          eyebrow: stepEyebrow,
                          title: stepTitle,
                          subtitle: stepSubtitle,
                          accentColor: stepAccentColor,
                          icon: stepIcon,
                          banner: stepBanner,
                          child: stepContent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pied fixe : barre d'actions ancrée hors du défilement, identique
              // pour toutes les étapes (PARCOURS 21). Dernier chrome à survivre :
              // sans lui, plus moyen de poursuivre la saisie.
              controls,
            ],
          ),
        );
      },
    );
  }
}
