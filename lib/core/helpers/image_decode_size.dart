import 'package:flutter/widgets.dart';

/// Largeur, en pixels physiques, à laquelle décoder une image montrée sur
/// [logicalSize] dp : une photo de 12 mégapixels affichée en vignette
/// occupait sa pleine résolution en mémoire — sensible dans un navigateur.
int imageDecodeWidth(BuildContext context, double logicalSize) =>
    (logicalSize * MediaQuery.devicePixelRatioOf(context)).ceil();
