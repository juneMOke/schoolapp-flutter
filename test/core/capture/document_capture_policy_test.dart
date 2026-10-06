import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_failure.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_capture_service.dart';
import 'package:school_app_flutter/core/capture/document_digest.dart';
import 'package:school_app_flutter/core/capture/document_type_sniffer.dart';

import 'capture_fixtures.dart';

/// Une politique par usage : les ressources d'un chapitre acceptent Word et
/// montent à 10 Mo ; les pièces du personnel restent à 5 Mo, sans Word.
void main() {
  final docx = Uint8List.fromList([
    0x50,
    0x4B,
    0x03,
    0x04,
    ...'....[Content_Types].xml...word/document.xml'.codeUnits,
  ]);
  final xlsx = Uint8List.fromList([
    0x50,
    0x4B,
    0x03,
    0x04,
    ...'....xl/workbook.xml'.codeUnits,
  ]);
  final doc = Uint8List.fromList([
    0xD0,
    0xCF,
    0x11,
    0xE0,
    0xA1,
    0xB1,
    0x1A,
    0xE1,
    0,
    0,
  ]);

  Future<DocumentDigest> digest(Uint8List bytes, DocumentMimeType type) async =>
      DocumentDigest(bytes: bytes, sha256Hex: 'sha');

  test('le renifleur reconnaît Word, pas un autre ZIP', () {
    expect(DocumentTypeSniffer.sniff(docx), DocumentMimeType.docx);
    expect(DocumentTypeSniffer.sniff(doc), DocumentMimeType.doc);
    expect(DocumentTypeSniffer.sniff(xlsx), isNull);
    expect(DocumentMimeType.docx.isImage, isFalse);
  });

  test(
    'un document Word passe pour une ressource, pas pour une pièce',
    () async {
      final gateway = FakeDocumentCaptureGateway(next: RawCapture(bytes: docx));
      final service = DocumentCaptureService(gateway, digest: digest);

      final resource = await service.capture(
        DocumentCaptureMode.importPdf,
        policy: DocumentCapturePolicy.courseResource,
      );
      expect(resource.isRight(), isTrue);
      expect(gateway.lastPolicy, DocumentCapturePolicy.courseResource);

      final staff = await service.capture(DocumentCaptureMode.importPdf);
      expect(
        staff.fold((f) => f, (_) => null),
        isA<UnsupportedDocumentFailure>(),
      );
    },
  );

  test('10 Mo pour une ressource, 5 Mo pour une pièce', () {
    expect(DocumentCapturePolicy.courseResource.maxBytes, 10 * 1024 * 1024);
    expect(DocumentCapturePolicy.staffDocument.maxBytes, 5 * 1024 * 1024);
    expect(DocumentCapturePolicy.courseResource.acceptsWord, isTrue);
    expect(DocumentCapturePolicy.staffDocument.acceptsWord, isFalse);
  });
}
