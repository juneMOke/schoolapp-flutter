import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La hauteur d'un graphique pour la largeur qu'il reçoit : [min] sur un
/// téléphone ou une tablette, puis proportionnelle à la largeur
/// ([AppDimensions.chartHeightToWidthRatio]), jusqu'à
/// [AppDimensions.chartMaxHeight].
abstract final class ChartHeight {
  static double forWidth(double width, {required double min}) {
    if (!width.isFinite) return min;
    final height = width * AppDimensions.chartHeightToWidthRatio;
    return height.clamp(min, AppDimensions.chartMaxHeight).toDouble();
  }
}
