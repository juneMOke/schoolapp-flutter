import 'dart:ui';

import 'package:flutter/material.dart';

/// Défilement de l'application.
///
/// Le doigt, le stylet et le pavé tactile font glisser le contenu ; la
/// souris, non : sur un poste de bureau, glisser à la souris SÉLECTIONNE le
/// texte (matricule, référence, montant) au lieu de faire défiler la page.
/// La molette, Maj+molette pour l'horizontal et la barre de défilement
/// (cf. `AppTheme.scrollbarTheme`, saisissable) font le reste.
///
/// Material ne pose de barre que sur l'axe VERTICAL : sans celle-ci, un
/// tableau plus large que l'écran n'offrirait à la souris aucune prise sur
/// ses colonnes cachées. On l'ajoute donc sur l'horizontal, sur bureau (et
/// sur le navigateur d'un bureau) ; la tablette garde son doigt.
///
/// Sur bureau, la barre verticale reste affichée : à la souris, c'est le seul
/// signe qu'une page ou une liste continue sous le bord de la fenêtre
/// (Material ne la montre qu'au défilement ou au survol de sa piste).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (!_isDesktop(getPlatform(context))) {
      return super.buildScrollbar(context, child, details);
    }
    final vertical = axisDirectionToAxis(details.direction) == Axis.vertical;
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: vertical,
      child: child,
    );
  }

  static bool _isDesktop(TargetPlatform platform) => switch (platform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.iOS => false,
  };

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}
