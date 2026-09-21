import 'package:flutter/widgets.dart';

/// Mélanges de couleurs opaques du design system.
///
/// Les specs couleurs expriment leurs surfaces en `color-mix(in srgb, …)` et
/// **publient les valeurs résultantes** : `#184662`, `#E8EDF0`, `#F6EAEF`… Ces
/// valeurs sont un contrat, pas une approximation — un écran doit les
/// reproduire exactement, sans quoi le code et le design system divergent en
/// silence.
///
/// ## Pourquoi ne pas employer `Color.lerp`
///
/// Deux raisons, et la seconde est la vraie.
///
/// 1. `Color.lerp` **tronque** là où les specs arrondissent : sur le seul fond
///    de pavé bleu, le canal vert tombe à 69,96 — 70 par arrondi, 69 par
///    troncature. Une unité d'écart, invisible à l'œil, mais qui fait échouer
///    toute vérification par valeur.
/// 2. Sa sémantique a déjà changé d'une version de Flutter à l'autre (passage
///    des canaux entiers aux canaux flottants). Une valeur de marque ne peut
///    pas dépendre de l'implémentation du framework.
class ColorMix {
  const ColorMix._();

  /// [t] parts de [other] pour `1 - t` de [base], canal par canal, avec
  /// **arrondi** — la convention des specs.
  static Color mix(Color base, Color other, double t) {
    int channel(double a, double b) =>
        (((a + (b - a) * t) * 255).round()).clamp(0, 255);
    return Color.fromARGB(
      255,
      channel(base.r, other.r),
      channel(base.g, other.g),
      channel(base.b, other.b),
    );
  }

  /// Dilue [tone] à [percent] % dans [surface] — la formule des **surfaces
  /// claires** (fonds de carte teintée, voiles de médaillon).
  static Color tint(Color surface, Color tone, int percent) =>
      mix(surface, tone, percent / 100);

  /// Assombrit [accent] vers [ground] en n'en gardant que [share] — la formule
  /// des **surfaces sombres** (fonds de pavé). C'est cet assombrissement qui
  /// rend une encre crème lisible sans changer l'identité de la couleur.
  static Color darken(Color ground, Color accent, double share) =>
      mix(ground, accent, share);
}
