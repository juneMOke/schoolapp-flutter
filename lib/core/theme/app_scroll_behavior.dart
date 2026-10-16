import 'dart:ui';

import 'package:flutter/material.dart';

/// Défilement de l'application.
///
/// Le doigt, le stylet et le pavé tactile font glisser le contenu ; la
/// souris, non : sur un poste de bureau, glisser à la souris SÉLECTIONNE le
/// texte (matricule, référence, montant) au lieu de faire défiler la page.
/// La molette, Maj+molette pour l'horizontal et la barre de défilement
/// (cf. `AppTheme.scrollbarTheme`, saisissable) font le reste.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}
