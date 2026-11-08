import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_reissue.dart';

EditiqueDocument _returned({String? documentId = 'doc-2', String? emittedOn}) =>
    EditiqueDocument(
      type: EditiqueDocumentType.enrollmentAttestation,
      bytes: Uint8List(4),
      fileName: 'piece.pdf',
      documentId: documentId,
      emittedOn: emittedOn,
    );

void main() {
  group('isPriorReplacement', () {
    const today = '2026-11-08';

    test('composée aujourd\'hui : neuve', () {
      expect(
        isPriorReplacement(
          _returned(emittedOn: today),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isFalse,
      );
    });

    test('émise un jour antérieur : déjà là, rendue telle quelle', () {
      expect(
        isPriorReplacement(
          _returned(emittedOn: '2026-11-07'),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isTrue,
      );
    });

    test('la pièce envoyée elle-même : rien n\'a été remplacé', () {
      expect(
        isPriorReplacement(
          _returned(documentId: 'doc-1', emittedOn: today),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isTrue,
      );
    });

    test('jour inconnu : on ne prétend rien', () {
      expect(
        isPriorReplacement(_returned(), sentDocumentId: 'doc-1', today: today),
        isFalse,
      );
    });
  });
}
