import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_failure.dart';
import 'package:school_app_flutter/core/capture/document_digest.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_capture_service.dart';
import 'package:school_app_flutter/core/capture/document_type_sniffer.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';

import 'capture_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 9, 29, 10);
  late FakeDocumentCaptureGateway gateway;
  late DocumentCaptureService service;

  setUp(() {
    gateway = FakeDocumentCaptureGateway();
    service = DocumentCaptureService(
      gateway,
      digest: digestDocument,
      now: () => now,
    );
  });

  Future<Object> captureOutcome(DocumentCaptureMode mode) async {
    final result = await service.capture(mode);
    return result.fold<Object>((failure) => failure, (document) => document);
  }

  group('DocumentTypeSniffer', () {
    test('reconnaît JPEG, PNG et PDF à leurs premiers octets', () {
      expect(DocumentTypeSniffer.sniff(jpegBytes), DocumentMimeType.jpeg);
      expect(DocumentTypeSniffer.sniff(pngBytes), DocumentMimeType.png);
      expect(DocumentTypeSniffer.sniff(pdfBytes), DocumentMimeType.pdf);
    });

    test('rend null pour un autre contenu ou un fichier trop court', () {
      expect(DocumentTypeSniffer.sniff(textBytes), isNull);
      expect(DocumentTypeSniffer.sniff(Uint8List.fromList([0xFF])), isNull);
      expect(DocumentTypeSniffer.sniff(Uint8List(0)), isNull);
    });
  });

  test('une numérisation rend la pièce, son empreinte et son heure', () async {
    gateway.next = RawCapture(bytes: jpegBytes, fileName: 'image_picker.jpg');

    final outcome = await captureOutcome(DocumentCaptureMode.scan);

    expect(outcome, isA<CapturedDocument>());
    final document = outcome as CapturedDocument;
    expect(document.mimeType, DocumentMimeType.jpeg);
    expect(document.source, DocumentCaptureSource.scan);
    expect(document.sha256Hex, await sha256Hex(jpegBytes));
    expect(document.capturedAt, now);
    // Le nom qu'invente la caméra ne dit rien de la pièce.
    expect(document.fileName, isNull);
    expect(gateway.calls, [DocumentCaptureMode.scan]);
  });

  test("un import garde le nom d'origine du fichier", () async {
    gateway.next = RawCapture(bytes: pdfBytes, fileName: 'diplome.pdf');

    final document =
        await captureOutcome(DocumentCaptureMode.importPdf) as CapturedDocument;

    expect(document.mimeType, DocumentMimeType.pdf);
    expect(document.source, DocumentCaptureSource.import);
    expect(document.fileName, 'diplome.pdf');
  });

  test('le type est jugé aux octets, pas au nom du fichier', () async {
    gateway.next = RawCapture(bytes: textBytes, fileName: 'faux.pdf');

    expect(
      await captureOutcome(DocumentCaptureMode.importPdf),
      isA<UnsupportedDocumentFailure>(),
    );
  });

  test('une pièce au-delà du plafond est refusée avec son poids', () async {
    final heavy = Uint8List(DocumentCapturePolicy.staffDocument.maxBytes + 1)
      ..setAll(0, pdfBytes);
    gateway.next = RawCapture(bytes: heavy);

    final outcome = await captureOutcome(DocumentCaptureMode.importPdf);

    expect(outcome, DocumentTooLargeFailure(heavy.length));
  });

  test('une pièce exactement au plafond passe', () async {
    final atLimit = Uint8List(DocumentCapturePolicy.staffDocument.maxBytes)
      ..setAll(0, pdfBytes);
    gateway.next = RawCapture(bytes: atLimit);

    expect(
      await captureOutcome(DocumentCaptureMode.importPdf),
      isA<CapturedDocument>(),
    );
  });

  test('renoncer rend un échec silencieux', () async {
    gateway.next = null;

    expect(
      await captureOutcome(DocumentCaptureMode.importImage),
      isA<DocumentCaptureCancelled>(),
    );
  });

  test('une caméra refusée est distinguée des autres pannes', () async {
    gateway.error = const CameraUnavailableException();
    expect(
      await captureOutcome(DocumentCaptureMode.scan),
      isA<CameraUnavailableFailure>(),
    );

    gateway.error = StateError('greffon en échec');
    expect(
      await captureOutcome(DocumentCaptureMode.scan),
      isA<DocumentReadFailure>(),
    );
  });

  test('un PDF annoncé trop lourd est refusé sans être lu', () async {
    gateway.error = const DocumentTooLargeException(200 * 1024 * 1024);

    expect(
      await captureOutcome(DocumentCaptureMode.importPdf),
      const DocumentTooLargeFailure(200 * 1024 * 1024),
    );
  });

  test(
    "l'empreinte porte sur les octets nettoyés, ceux qui partiront",
    () async {
      final cleaned = Uint8List.fromList([...jpegBytes, 0xAA]);
      gateway.next = RawCapture(bytes: jpegBytes);
      service = DocumentCaptureService(
        gateway,
        digest: (bytes, type) async =>
            DocumentDigest(bytes: cleaned, sha256Hex: await sha256Hex(cleaned)),
      );

      final document =
          await captureOutcome(DocumentCaptureMode.scan) as CapturedDocument;

      expect(document.bytes, cleaned);
      expect(document.sha256Hex, await sha256Hex(cleaned));
    },
  );

  test('un calcul en échec est une lecture ratée', () async {
    gateway.next = RawCapture(bytes: pdfBytes);
    service = DocumentCaptureService(
      gateway,
      digest: (_, _) async => throw StateError('isolat mort-né'),
    );

    expect(
      await captureOutcome(DocumentCaptureMode.importPdf),
      isA<DocumentReadFailure>(),
    );
  });
}
