import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/jpeg_metadata_sanitizer.dart';

/// Segment d'en-tête JPEG : marqueur, longueur, charge utile.
List<int> _segment(int marker, List<int> payload) {
  final length = payload.length + 2;
  return [0xFF, marker, length >> 8, length & 0xFF, ...payload];
}

/// Segment APP1 EXIF en petit-boutiste, IFD0 portant l'orientation puis un
/// pointeur vers un IFD GPS (étiquette 0x8825) suivi de coordonnées factices.
List<int> _exifWithGps({required int orientation}) {
  final tiff = <int>[
    0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00, // II, IFD0 à 8
    0x02, 0x00, // deux entrées
    0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, orientation, 0x00, 0, 0,
    0x25, 0x88, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x26, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, // pas d'IFD suivant
    ...'GPS-4.3217S-15.3125E'.codeUnits, // position qui ne doit pas survivre
  ];
  return _segment(0xE1, [0x45, 0x78, 0x69, 0x66, 0x00, 0x00, ...tiff]);
}

final List<int> _jfif = _segment(0xE0, 'JFIF\u0000'.codeUnits);
final List<int> _xmp = _segment(
  0xE1,
  'http://ns.adobe.com/xap/1.0/ GPS'.codeUnits,
);
final List<int> _quantTable = _segment(0xDB, List<int>.filled(8, 7));
const List<int> _scan = [
  0xFF, 0xDA, 0x00, 0x04, 0x01, 0x00, // SOS
  0x12, 0x34, 0xFF, 0x00, 0x56, // données compressées
  0xFF, 0xD9, // EOI
];

Uint8List _jpeg(List<List<int>> headers) => Uint8List.fromList([
  0xFF, 0xD8, //
  for (final h in headers) ...h,
  ..._scan,
]);

bool _contains(Uint8List haystack, String needle) =>
    String.fromCharCodes(haystack).contains(needle);

void main() {
  test("retire l'EXIF et le XMP, rétablit l'orientation seule", () {
    final input = _jpeg([
      _jfif,
      _exifWithGps(orientation: 6),
      _xmp,
      _quantTable,
    ]);

    final output = JpegMetadataSanitizer.sanitize(input);

    expect(_contains(output, 'GPS'), isFalse);
    expect(_contains(output, 'adobe'), isFalse);
    // JFIF d'abord, puis l'EXIF minimal (orientation 6), puis le reste intact.
    final expectedExif = [
      0xFF, 0xE1, 0x00, 0x22, //
      0x45, 0x78, 0x69, 0x66, 0x00, 0x00,
      0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08,
      0x00, 0x01,
      0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01,
      0x00, 0x06, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
    ];
    expect(output, [
      0xFF,
      0xD8,
      ..._jfif,
      ...expectedExif,
      ..._quantTable,
      ..._scan,
    ]);
  });

  test("sans orientation à rétablir, aucun segment EXIF n'est ajouté", () {
    final input = _jpeg([_exifWithGps(orientation: 1), _quantTable]);

    final output = JpegMetadataSanitizer.sanitize(input);

    expect(output, [0xFF, 0xD8, ..._quantTable, ..._scan]);
  });

  test('sans JFIF, l\'EXIF minimal suit directement le SOI', () {
    final input = _jpeg([_exifWithGps(orientation: 3), _quantTable]);

    final output = JpegMetadataSanitizer.sanitize(input);

    expect(output.sublist(0, 4), [0xFF, 0xD8, 0xFF, 0xE1]);
    expect(output.sublist(output.length - _scan.length), _scan);
  });

  test('un JPEG sans métadonnées ressort à l\'identique', () {
    final input = _jpeg([_jfif, _quantTable]);

    expect(JpegMetadataSanitizer.sanitize(input), input);
  });

  test("ce qui n'est pas un JPEG est rendu tel quel", () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    final pdf = Uint8List.fromList('%PDF-1.7'.codeUnits);

    expect(identical(JpegMetadataSanitizer.sanitize(png), png), isTrue);
    expect(identical(JpegMetadataSanitizer.sanitize(pdf), pdf), isTrue);
  });

  test('un segment tronqué arrête le parcours sans lever', () {
    final truncated = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE1,
      0x7F,
      0xFF,
      1,
    ]);

    expect(() => JpegMetadataSanitizer.sanitize(truncated), returnsNormally);
  });
}
