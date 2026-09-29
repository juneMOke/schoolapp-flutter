import 'dart:typed_data';

/// Retire d'un JPEG les métadonnées qui peuvent le localiser ou l'identifier
/// (EXIF, dont le GPS ; XMP ; IPTC), en ne gardant que l'**orientation**.
///
/// Nécessaire parce que `image_picker` sur Android ignore
/// `requestFullMetadata: false` et recopie toute l'EXIF de l'appareil photo,
/// coordonnées GPS comprises, dans l'image réduite. Une pièce d'identité n'a
/// pas à emporter l'endroit où elle a été photographiée.
///
/// L'orientation, elle, est rétablie dans un segment EXIF minimal : Android ne
/// fait pas pivoter les pixels, il s'en remet à cette étiquette, et la retirer
/// ferait apparaître la pièce couchée.
///
/// Fonction pure, sans décodage d'image : seuls les segments d'en-tête sont
/// parcourus, les données compressées sont recopiées telles quelles.
class JpegMetadataSanitizer {
  JpegMetadataSanitizer._();

  static const int _soi = 0xD8;
  static const int _sos = 0xDA;
  static const int _eoi = 0xD9;
  static const int _app0 = 0xE0;
  static const int _app1 = 0xE1; // EXIF et XMP
  static const int _app13 = 0xED; // IPTC (Photoshop)
  static const int _orientationTag = 0x0112;

  /// [bytes] sans EXIF/XMP/IPTC, orientation conservée. Un contenu qui n'est
  /// pas un JPEG est rendu tel quel.
  static Uint8List sanitize(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != _soi) return bytes;

    final out = BytesBuilder(copy: false)..add(bytes.sublist(0, 2));
    int? orientation;
    var insertAt = 2;
    var i = 2;

    while (i + 4 <= bytes.length && bytes[i] == 0xFF) {
      final marker = bytes[i + 1];
      if (marker == _sos || marker == _eoi) break;
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      final end = i + 2 + length;
      if (length < 2 || end > bytes.length) break;

      final isStripped = marker == _app1 || marker == _app13;
      if (marker == _app1) {
        orientation ??= _orientationOf(bytes, i + 4, end);
      } else if (!isStripped) {
        out.add(bytes.sublist(i, end));
        // Le segment JFIF doit rester le premier : l'EXIF minimal le suit.
        if (marker == _app0 && insertAt == 2) insertAt = out.length;
      }
      i = end;
    }
    out.add(bytes.sublist(i));

    final result = out.takeBytes();
    if (orientation == null || orientation == 1) return result;
    return Uint8List.fromList([
      ...result.sublist(0, insertAt),
      ..._minimalExif(orientation),
      ...result.sublist(insertAt),
    ]);
  }

  /// Valeur de l'étiquette d'orientation d'un segment APP1 EXIF couvrant
  /// `[start, end)`, ou `null` si le segment n'en porte pas (ou est abîmé).
  static int? _orientationOf(Uint8List b, int start, int end) {
    const header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // "Exif\0\0"
    if (end - start < header.length + 8) return null;
    for (var k = 0; k < header.length; k++) {
      if (b[start + k] != header[k]) return null;
    }
    final tiff = start + header.length;
    final bool little;
    if (b[tiff] == 0x49 && b[tiff + 1] == 0x49) {
      little = true;
    } else if (b[tiff] == 0x4D && b[tiff + 1] == 0x4D) {
      little = false;
    } else {
      return null;
    }
    int u16(int at) =>
        little ? b[at] | (b[at + 1] << 8) : (b[at] << 8) | b[at + 1];
    int u32(int at) =>
        little ? u16(at) | (u16(at + 2) << 16) : (u16(at) << 16) | u16(at + 2);

    final ifd = tiff + u32(tiff + 4);
    if (ifd + 2 > end) return null;
    final count = u16(ifd);
    for (var e = 0; e < count; e++) {
      final entry = ifd + 2 + e * 12;
      if (entry + 12 > end) return null;
      if (u16(entry) != _orientationTag) continue;
      final value = u16(entry + 8);
      return value >= 1 && value <= 8 ? value : null;
    }
    return null;
  }

  /// Segment APP1 EXIF réduit à la seule orientation (TIFF gros-boutiste).
  static List<int> _minimalExif(int orientation) {
    const payload = <int>[
      0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // "Exif\0\0"
      0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // TIFF, IFD0 à 8
      0x00, 0x01, // une entrée
      0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, // orientation, SHORT ×1
    ];
    final body = [
      ...payload,
      0x00, orientation, 0x00, 0x00, // valeur
      0x00, 0x00, 0x00, 0x00, // pas d'IFD suivant
    ];
    final length = body.length + 2;
    return [0xFF, _app1, length >> 8, length & 0xFF, ...body];
  }
}
