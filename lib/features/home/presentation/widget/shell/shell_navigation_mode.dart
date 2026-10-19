import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Comment la coquille offre son menu, selon la largeur disponible.
enum ShellNavigationMode {
  /// Téléphone, 7" portrait : barre d'en-tête à hamburger, menu en tiroir.
  drawer,

  /// 10" portrait, 7" paysage : barre latérale fixée en rail de 84 dp ; son
  /// écusson ouvre le menu complet en tiroir.
  rail,

  /// Au-delà : barre latérale ancrée, dépliée ou repliée au choix.
  sidebar;

  static ShellNavigationMode forWidth(double width) {
    if (width < AppBreakpoints.navigationDrawerMax) return drawer;
    if (width < AppBreakpoints.navigationCompactMax) return rail;
    return sidebar;
  }

  bool get isDrawer => this == drawer;

  /// La coquille tient un tiroir : seul menu en [drawer], menu complet
  /// derrière le rail en [rail].
  bool get hasDrawer => this != sidebar;
}
