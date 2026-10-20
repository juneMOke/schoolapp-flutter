import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// La hauteur d'une commande qu'on actionne ligne après ligne (segment
/// d'appel, heure, « Justifier ») : 48 dp au doigt, 40 à la souris.
///
/// Le thème le sait déjà : `materialTapTargetSize` est `padded` sur les
/// plateformes tactiles, `shrinkWrap` au bureau — navigateur de bureau compris.
/// À la souris, 48 dp par ligne coûtaient un élève sur cinq à l'écran d'un
/// portable.
abstract final class TapTargetHeight {
  static double of(BuildContext context) =>
      Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded
      ? AppDimensions.minTouchTarget
      : AppDimensions.pointerControlHeight;
}
