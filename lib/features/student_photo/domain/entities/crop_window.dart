import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Le carré retenu dans une image, en pixels de l'image.
///
/// Le carré **couvre toujours** l'image : il ne sort jamais de ses bords, si
/// bien que la photo n'a jamais de bande vide. Zoom 1 = le plus grand carré
/// possible ; zoom 3 = un carré trois fois plus petit.
class CropWindow extends Equatable {
  final double imageWidth;
  final double imageHeight;
  final double zoom;
  final double centerX;
  final double centerY;

  static const double minZoom = 1;
  static const double maxZoom = 3;

  const CropWindow._({
    required this.imageWidth,
    required this.imageHeight,
    required this.zoom,
    required this.centerX,
    required this.centerY,
  });

  /// Le plus grand carré, centré.
  factory CropWindow.centered(double width, double height) =>
      CropWindow._clamped(width, height, minZoom, width / 2, height / 2);

  /// Le carré que dessine le guide ovale du viseur : 78 % du petit côté,
  /// centré horizontalement et à 46 % de la hauteur — là où l'élève a placé
  /// son visage.
  factory CropWindow.ovalGuide(double width, double height) =>
      CropWindow._clamped(width, height, 1 / 0.78, width / 2, height * 0.46);

  factory CropWindow._clamped(
    double width,
    double height,
    double zoom,
    double centerX,
    double centerY,
  ) {
    final z = zoom.clamp(minZoom, maxZoom).toDouble();
    final side = math.min(width, height) / z;
    final half = side / 2;
    return CropWindow._(
      imageWidth: width,
      imageHeight: height,
      zoom: z,
      centerX: centerX.clamp(half, width - half).toDouble(),
      centerY: centerY.clamp(half, height - half).toDouble(),
    );
  }

  /// Côté du carré, en pixels de l'image.
  double get side => math.min(imageWidth, imageHeight) / zoom;

  double get left => centerX - side / 2;
  double get top => centerY - side / 2;

  /// Déplace l'image de ([dx], [dy]) dp dans une vue carrée de [viewSide] dp :
  /// faire glisser l'image vers la droite montre ce qui est à sa gauche.
  CropWindow panBy(double dx, double dy, double viewSide) {
    final pixelsPerDp = side / viewSide;
    return CropWindow._clamped(
      imageWidth,
      imageHeight,
      zoom,
      centerX - dx * pixelsPerDp,
      centerY - dy * pixelsPerDp,
    );
  }

  /// Change le zoom autour du centre courant.
  CropWindow zoomTo(double value) =>
      CropWindow._clamped(imageWidth, imageHeight, value, centerX, centerY);

  /// Le carré en fractions de l'image (0 à 1 sur chaque axe) — la forme que
  /// le recadrage reçoit, indépendante de la résolution décodée.
  ({double left, double top, double width, double height}) get fraction => (
    left: left / imageWidth,
    top: top / imageHeight,
    width: side / imageWidth,
    height: side / imageHeight,
  );

  @override
  List<Object?> get props => [imageWidth, imageHeight, zoom, centerX, centerY];
}
