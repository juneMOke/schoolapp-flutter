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

  /// Conteneur OLE2 : le `.doc` historique de Word.
  static const List<int> _ole = [
    0xD0,
    0xCF,
    0x11,
    0xE0,
    0xA1,
    0xB1,
    0x1A,
    0xE1,
  ];

  /// Archive ZIP : un `.docx` en est une, comme un `.xlsx` ou un `.zip`.
  static const List<int> _zip = [0x50, 0x4B, 0x03, 0x04];

  /// L'arborescence que seul un document Word porte dans son archive. Les
  /// noms des entrées sont en clair dans les en-têtes locaux du ZIP.
  static final List<int> _wordEntry = 'word/'.codeUnits;

  /// Le type de [bytes], ou `null` s'il n'est pas l'un des types reconnus.
  static DocumentMimeType? sniff(Uint8List bytes) {
    if (_startsWith(bytes, _jpeg)) return DocumentMimeType.jpeg;
    if (_startsWith(bytes, _png)) return DocumentMimeType.png;
    if (_startsWith(bytes, _pdf)) return DocumentMimeType.pdf;
    if (_startsWith(bytes, _ole)) return DocumentMimeType.doc;
    if (_startsWith(bytes, _zip) && _contains(bytes, _wordEntry)) {
      return DocumentMimeType.docx;
    }
    return null;
  }

  static bool _contains(Uint8List bytes, List<int> needle) {
    final last = bytes.length - needle.length;
    outer:
    for (var i = 0; i <= last; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}
