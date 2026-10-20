import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La grille des classes de l'organisation (cartes et leur squelette) : le
/// nombre de colonnes et la largeur d'une carte pour une largeur reçue.
abstract final class ClassesGridLayout {
  static const double gap = AppDimensions.spacingM;

  static int columnsFor(double width) =>
      width >= AppBreakpoints.classesGridFourColMin
      ? 4
      : width >= AppBreakpoints.classesGridThreeColMin
      ? 3
      : width >= AppBreakpoints.classesGridTwoColMin
      ? 2
      : 1;

  static double cardWidthFor(double width) {
    final columns = columnsFor(width);
    return columns <= 1 ? width : (width - (columns - 1) * gap) / columns;
  }
}
