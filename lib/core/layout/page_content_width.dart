import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Le plafond de largeur d'une page, selon ce qu'elle montre.
enum PageContentWidth {
  /// Une fiche ou un formulaire : une ligne de texte ne s'étire pas au-delà de
  /// la largeur de lecture.
  reading,

  /// Une liste, un tableau, un tableau de bord, une grille : des colonnes qui
  /// gagnent à s'élargir. Plus large encore sur un écran 1920 et au-delà,
  /// sans quoi 400 dp restaient vides de chaque côté.
  wide;

  /// Plafond pour la fenêtre de [context] — la page, sa barre du bas et ses
  /// blocs internes s'alignent ainsi sur les mêmes bords.
  double maxWidthIn(BuildContext context) =>
      maxWidthFor(MediaQuery.sizeOf(context).width);

  /// Plafond pour une fenêtre de [viewportWidth] dp.
  double maxWidthFor(double viewportWidth) => switch (this) {
    reading => AppDimensions.detailContentMaxWidth,
    wide =>
      viewportWidth >= AppBreakpoints.xlarge
          ? AppDimensions.wideContentMaxWidthXL
          : AppDimensions.listingContentMaxWidth,
  };
}
