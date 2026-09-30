import 'dart:typed_data';

import 'package:school_app_flutter/core/capture/captured_document.dart';

/// Reconnaît le type d'une pièce à ses premiers octets (« nombre magique »).
///
/// L'extension et le type annoncé par la plateforme ne prouvent rien : un
/// fichier renommé garde son contenu, et le serveur, lui, jugera le contenu.
class DocumentTypeSniffer {
  DocumentTypeSniffer._();

  static const List<int> _jpeg = [0xFF, 0xD8, 0xFF];
  static const List<int> _png = [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];
  static const List<int> _pdf = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-

  /// Le type de [bytes], ou `null` s'il n'est pas l'un des trois reconnus.
  static DocumentMimeType? sniff(Uint8List bytes) {
    if (_startsWith(bytes, _jpeg)) return DocumentMimeType.jpeg;
    if (_startsWith(bytes, _png)) return DocumentMimeType.png;
    if (_startsWith(bytes, _pdf)) return DocumentMimeType.pdf;
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}
