import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Densité du chrome fixe du parcours d'inscription — barre d'étapes et marges
/// — en fonction de la hauteur **réellement disponible**.
///
/// Le clavier logiciel ne se superpose pas à l'écran : il en retire la hauteur
/// (`resizeToAvoidBottomInset`). Sur un téléphone en paysage il ne reste alors
/// qu'une centaine de dp au stepper, quand la barre d'étapes complète, son
/// écart et le pied d'actions en coûtent près du double — la colonne débordait.
///
/// Le chrome se raréfie donc à mesure que la place manque, et c'est toujours le
/// contenu — le champ en cours de saisie — qui garde ce qui reste. Le seuil
/// porte sur la hauteur disponible et non sur la présence du clavier : un petit
/// écran mérite le même ménagement, et la règle reste vérifiable sans clavier.
enum WizardChromeDensity {
  /// Barre d'étapes complète (chips numérotés + libellés), marges pleines.
  full,

  /// Barre réduite à sa seule barre de progression, marges resserrées : les
  /// chips ne sont de toute façon pas actionnables pendant une saisie, alors
  /// que la progression, elle, situe encore.
  slim,

  /// Plus de barre du tout — seul le pied d'actions survit, sans quoi l'écran
  /// n'offrirait plus de quoi poursuivre.
  minimal;

  /// [availableHeight] est la hauteur offerte à la colonne du stepper.
  ///
  /// Une hauteur non finie (colonne placée dans un défilement) rend la question
  /// sans objet : il n'y a alors aucune place à ménager, donc chrome complet.
  static WizardChromeDensity forHeight(double availableHeight) {
    if (!availableHeight.isFinite) return WizardChromeDensity.full;
    if (availableHeight < AppBreakpoints.wizardStepperBreadcrumbMinHeight) {
      return WizardChromeDensity.minimal;
    }
    if (availableHeight < AppBreakpoints.wizardStepperFullChromeMinHeight) {
      return WizardChromeDensity.slim;
    }
    return WizardChromeDensity.full;
  }

  /// Vrai tant qu'il reste de quoi afficher une barre, fût-elle réduite.
  bool get showsBreadcrumb => this != WizardChromeDensity.minimal;

  /// Vrai quand la barre affichée doit se réduire à sa progression.
  bool get usesCompactBreadcrumb => this == WizardChromeDensity.slim;

  /// Vrai quand les marges peuvent rester pleines.
  bool get usesFullSpacing => this == WizardChromeDensity.full;
}
