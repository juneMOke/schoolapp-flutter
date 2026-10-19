import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Comment la coquille offre son menu, selon la largeur disponible.
enum ShellNavigationMode {
  /// Téléphone, petite tablette : barre d'en-tête et menu en tiroir.
  drawer,

  /// Au-delà : barre latérale ancrée (dépliée ou repliée en rail).
  sidebar;

  static ShellNavigationMode forWidth(double width) =>
      width < AppBreakpoints.navigationCompactMax ? drawer : sidebar;

  bool get isDrawer => this == drawer;
}
