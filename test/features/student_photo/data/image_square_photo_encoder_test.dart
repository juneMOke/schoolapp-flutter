import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:school_app_flutter/features/student_photo/data/photo/image_square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';

/// Une image [width] × 200 : moitié gauche rouge, moitié droite bleue.
Uint8List _halves({int width = 400}) {
  final image = img.Image(width: width, height: 200);
  for (var y = 0; y < 200; y++) {
    for (var x = 0; x < width; x++) {
      final red = x < width / 2;
      image.setPixelRgb(x, y, red ? 255 : 0, 0, red ? 0 : 255);
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

  test('en miroir, la photo se garde dans le VRAI sens : seul le choix du '
      'carré est retourné', () async {
    // Un carré qui couvre les deux moitiés : son contenu dit le sens gardé.
    final out = await encoder.encode(
      _halves(width: 200),
      CropWindow.centered(200, 200),
      mirror: true,
    );

    final decoded = img.decodeJpg(out)!;
    final left = decoded.getPixel(64, 256);
    final right = decoded.getPixel(448, 256);
    expect(left.r, greaterThan(200), reason: 'rouge à gauche, comme le réel');
    expect(right.b, greaterThan(200));
  });
}
