import 'dart:typed_data';

import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';

/// Les dimensions d'une image, telle qu'elle s'affiche (orientation EXIF
/// appliquée).
typedef PhotoDimensions = ({double width, double height});

/// La photo n'est pas une image lisible (JPG, PNG ou WebP).
class UnreadablePhotoException implements Exception {
  const UnreadablePhotoException();
}

/// Mesure une image et en tire le carré JPEG que le serveur accepte.
abstract class SquarePhotoEncoder {
  /// Côté du carré envoyé, en pixels.
  static const int outputSide = 512;

  /// Qualité JPEG du carré (≈ 60 Ko).
  static const int jpegQuality = 85;

  /// Lève [UnreadablePhotoException] si [bytes] ne se décodent pas.
  Future<PhotoDimensions> measure(Uint8List bytes);

  /// Le carré [window] de [bytes] — choisi sur l'image retournée en miroir si
  /// [mirror], comme l'écran la montrait —, en JPEG [outputSide] px. Les métadonnées (EXIF, GPS) ne survivent pas au
  /// ré-encodage.
  Future<Uint8List> encode(
    Uint8List bytes,
    CropWindow window, {
    bool mirror = false,
  });
}
