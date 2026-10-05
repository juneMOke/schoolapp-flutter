import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';

/// [SquarePhotoEncoder] sur le paquet `image`, hors du fil d'interface :
/// décoder une photo de 2 000 px figerait l'écran une demi-seconde sur une
/// tablette. `compute` passe par un isolat, et par le fil courant sur le web
/// qui n'en a pas.
class ImageSquarePhotoEncoder implements SquarePhotoEncoder {
  const ImageSquarePhotoEncoder();

  @override
  Future<PhotoDimensions> measure(Uint8List bytes) async {
    final size = await compute(_measure, bytes);
    if (size == null) throw const UnreadablePhotoException();
    return (width: size[0].toDouble(), height: size[1].toDouble());
  }

  @override
  Future<Uint8List> encode(
    Uint8List bytes,
    CropWindow window, {
    bool mirror = false,
  }) async {
    final f = window.fraction;
    final out = await compute(
      _encode,
      _EncodeRequest(
        bytes: bytes,
        left: f.left,
        top: f.top,
        width: f.width,
        height: f.height,
        mirror: mirror,
      ),
    );
    if (out == null) throw const UnreadablePhotoException();
    return out;
  }
}

class _EncodeRequest {
  final Uint8List bytes;
  final double left;
  final double top;
  final double width;
  final double height;
  final bool mirror;

  const _EncodeRequest({
    required this.bytes,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.mirror,
  });
}

/// L'image décodée, orientation EXIF appliquée — celle que l'écran montre.
img.Image? _decodeOriented(Uint8List bytes) {
  // Des octets qui ne sont pas une image font lever certains décodeurs au
  // lieu de rendre `null` : les deux se lisent « illisible ».
  try {
    final decoded = img.decodeImage(bytes);
    return decoded == null ? null : img.bakeOrientation(decoded);
  } catch (_) {
    return null;
  }
}

List<int>? _measure(Uint8List bytes) {
  final image = _decodeOriented(bytes);
  return image == null ? null : [image.width, image.height];
}

Uint8List? _encode(_EncodeRequest request) {
  final decoded = _decodeOriented(request.bytes);
  if (decoded == null) return null;
  // Le carré a été choisi sur l'image telle qu'elle s'affichait — en miroir
  // pour une caméra frontale : on la retourne donc AVANT de découper.
  final image = request.mirror ? img.flipHorizontal(decoded) : decoded;
  final x = (request.left * image.width).round().clamp(0, image.width - 1);
  final y = (request.top * image.height).round().clamp(0, image.height - 1);
  final side = math.max(
    1,
    math.min(
      math.min(
        (request.width * image.width).round(),
        (request.height * image.height).round(),
      ),
      math.min(image.width - x, image.height - y),
    ),
  );
  final square = img.copyCrop(image, x: x, y: y, width: side, height: side);
  final resized = img.copyResize(
    square,
    width: SquarePhotoEncoder.outputSide,
    height: SquarePhotoEncoder.outputSide,
    interpolation: img.Interpolation.average,
  );
  return img.encodeJpg(resized, quality: SquarePhotoEncoder.jpegQuality);
}
