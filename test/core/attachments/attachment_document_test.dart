import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:school_app_flutter/core/attachments/attachment_document.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';

void main() {
  AttachmentRef ref(String mime) =>
      AttachmentRef(name: 'p', mimeType: mime, sizeBytes: 1, sha256: mime);

  // Une vraie image, encodée ici : ce que la composition doit poser sur une
  // page.
  final png = img.encodePng(img.Image(width: 2, height: 2));
  final pdf = Uint8List.fromList('%PDF-1.4'.codeUnits);

  test('un PDF seul passe tel quel', () async {
    final document = await AttachmentDocument.compose([
      (ref: ref('application/pdf'), bytes: pdf),
    ], fileName: 'copie.pdf');
    expect(document!.bytes, pdf);
    expect(document.fileName, 'copie.pdf');
  });

  test('des photos deviennent un PDF', () async {
    final document = await AttachmentDocument.compose([
      (ref: ref('image/png'), bytes: png),
      (ref: ref('image/png'), bytes: png),
    ], fileName: 'copie.pdf');
    expect(String.fromCharCodes(document!.bytes.take(5)), '%PDF-');
  });

  test('un PDF parmi d autres pièces ne se compose pas', () async {
    final document = await AttachmentDocument.compose([
      (ref: ref('application/pdf'), bytes: pdf),
      (ref: ref('image/png'), bytes: png),
    ], fileName: 'copie.pdf');
    expect(document, isNull);
  });

  test('une image indécodable ne se compose pas, sans lever', () async {
    final document = await AttachmentDocument.compose([
      (ref: ref('image/jpeg'), bytes: pdf),
    ], fileName: 'x');
    expect(document, isNull);
  });

  test('une pièce illisible ne se compose pas', () async {
    final document = await AttachmentDocument.compose([
      (ref: ref('application/zip'), bytes: pdf),
    ], fileName: 'x');
    expect(document, isNull);
  });
}
