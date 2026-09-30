import 'dart:typed_data';

import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';

/// Octets minimaux portant la signature de chaque type accepté.
final Uint8List jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2]);
final Uint8List pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, //
]);
final Uint8List pdfBytes = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
final Uint8List textBytes = Uint8List.fromList('bonjour'.codeUnits);

/// Passerelle dont on choisit la réponse pour chaque geste.
class FakeDocumentCaptureGateway implements DocumentCaptureGateway {
  RawCapture? next;
  Object? error;
  final List<DocumentCaptureMode> calls = [];

  FakeDocumentCaptureGateway({this.next, this.error});

  @override
  Future<RawCapture?> acquire(DocumentCaptureMode mode) async {
    calls.add(mode);
    final failure = error;
    if (failure != null) throw failure;
    return next;
  }
}
