import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:school_app_flutter/features/student_photo/data/photo/image_square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';

/// Une image 400 × 200 : moitié gauche rouge, moitié droite bleue.
Uint8List _halves() {
  final image = img.Image(width: 400, height: 200);
  for (var y = 0; y < 200; y++) {
    for (var x = 0; x < 400; x++) {
      image.setPixelRgb(x, y, x < 200 ? 255 : 0, 0, x < 200 ? 0 : 255);
    }
  }
  return img.encodePng(image);
}

void main() {
  const encoder = ImageSquarePhotoEncoder();

  test('mesure l\'image', () async {
    final size = await encoder.measure(_halves());
    expect(size.width, 400);
    expect(size.height, 200);
  });

  test('des octets illisibles sont refusés', () async {
    expect(
      () => encoder.measure(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<UnreadablePhotoException>()),
    );
  });

  test('rend un carré JPEG de 512 px, du côté choisi', () async {
    final bytes = _halves();
    // Le carré de gauche : tout rouge.
    final left = CropWindow.centered(400, 200).panBy(1000, 0, 200);
    final out = await encoder.encode(bytes, left);

    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, SquarePhotoEncoder.outputSide);
    expect(decoded.height, SquarePhotoEncoder.outputSide);
    final pixel = decoded.getPixel(256, 256);
    expect(pixel.r, greaterThan(200));
    expect(pixel.b, lessThan(60));
  });

  test('en miroir, le carré est choisi sur l\'image retournée', () async {
    final bytes = _halves();
    final left = CropWindow.centered(400, 200).panBy(1000, 0, 200);
    final out = await encoder.encode(bytes, left, mirror: true);

    final pixel = img.decodeJpg(out)!.getPixel(256, 256);
    // Retournée, la moitié gauche est bleue.
    expect(pixel.b, greaterThan(200));
    expect(pixel.r, lessThan(60));
  });
}
