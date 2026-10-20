import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Les hauteurs de modale, lues sur la fenêtre.
abstract final class DialogHeight {
  /// Une modale à liste ou à document : la part
  /// [AppDimensions.dialogMaxHeightRatio] de la fenêtre.
  static double ofWindow(BuildContext context) =>
      MediaQuery.sizeOf(context).height * AppDimensions.dialogMaxHeightRatio;

  /// Une modale de saisie : [AppDimensions.formDialogMaxHeight] sur un
  /// portable, davantage sur un grand écran, jamais au-delà de
  /// [AppDimensions.formDialogTallMaxHeight].
  static double ofForm(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * AppDimensions.formDialogHeightRatio)
          .clamp(
            AppDimensions.formDialogMaxHeight,
            AppDimensions.formDialogTallMaxHeight,
          )
          .toDouble();
}
