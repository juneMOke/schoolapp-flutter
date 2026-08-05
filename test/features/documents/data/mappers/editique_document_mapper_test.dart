import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/mappers/editique_document_mapper.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Octets minimaux acceptés comme PDF : signature `%PDF` + un peu de contenu.
Uint8List _pdfBytes() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _response({
  Uint8List? bytes,
  String? contentType = 'application/pdf',
  String? contentDisposition,
  String? documentId,
}) {
  final headerMap = <String, List<String>>{};
  if (contentType != null) {
    headerMap[Headers.contentTypeHeader] = <String>[contentType];
  }
  if (contentDisposition != null) {
    headerMap['content-disposition'] = <String>[contentDisposition];
  }
  if (documentId != null) {
    headerMap['x-document-id'] = <String>[documentId];
  }

  return HttpResponse<Uint8List>(
    bytes ?? _pdfBytes(),
    Response<Uint8List>(
      requestOptions: RequestOptions(path: '/api/v1/whatever'),
      statusCode: 200,
      headers: Headers.fromMap(headerMap),
      data: bytes ?? _pdfBytes(),
    ),
  );
}

void main() {
  group('EditiqueDocumentMapper.map — cas nominal', () {
    test('produit un document avec son numéro et son nom de fichier', () {
      final result = EditiqueDocumentMapper.map(
        _response(
          contentDisposition: 'attachment; filename="ETL-AI-2526-000087.pdf"',
        ),
        EditiqueDocumentType.enrollmentAttestation,
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.type, EditiqueDocumentType.enrollmentAttestation);
      expect(document.fileName, 'ETL-AI-2526-000087.pdf');
      expect(document.documentNumber, 'ETL-AI-2526-000087');
      expect(document.bytes, _pdfBytes());
      expect(document.isReplayable, isTrue);
    });

    test('retient l\'identifiant d\'archive annoncé par le serveur', () {
      final result = EditiqueDocumentMapper.map(
        _response(documentId: '3f2504e0-4f89-41d3-9a0c-0305e82c3301'),
        EditiqueDocumentType.paymentReceipt,
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.documentId, '3f2504e0-4f89-41d3-9a0c-0305e82c3301');
    });

    // Régime normal de la moitié des pièces : un relevé ou un quitus n'est pas
    // archivé, donc le serveur n'a aucun identifiant à annoncer. C'est aussi ce
    // que rend un serveur antérieur à cet en-tête.
    test('sans identifiant annoncé, n\'en invente pas', () {
      final result = EditiqueDocumentMapper.map(
        _response(),
        EditiqueDocumentType.accountStatement,
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.documentId, isNull);
    });

    // « Inconnu » ne doit jamais s'écrire autrement que null : une chaîne vide
    // finirait indexée telle quelle dans le cache hors ligne.
    test('un identifiant vide vaut une absence', () {
      final result = EditiqueDocumentMapper.map(
        _response(documentId: '   '),
        EditiqueDocumentType.paymentReceipt,
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.documentId, isNull);
    });

    test('tolère un content-type paramétré', () {
      final result = EditiqueDocumentMapper.map(
        _response(contentType: 'application/pdf;charset=UTF-8'),
        EditiqueDocumentType.notePerception,
      );
      expect(result.isRight(), isTrue);
    });

    test(
      'construit un nom de repli quand le Content-Disposition est absent',
      () {
        final result = EditiqueDocumentMapper.map(
          _response(),
          EditiqueDocumentType.accountStatement,
        );

        final document = result.getOrElse(
          () => throw StateError('attendu Right'),
        );
        expect(document.fileName, 'document-rl.pdf');
        expect(document.documentNumber, isNull);
        expect(document.isReplayable, isFalse);
      },
    );
  });

  group('EditiqueDocumentMapper.map — refus', () {
    test('refuse un corps vide', () {
      final result = EditiqueDocumentMapper.map(
        _response(bytes: Uint8List(0)),
        EditiqueDocumentType.paymentReceipt,
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });

    // Un portail captif ou un proxy répond 200 avec du HTML : ces octets ne
    // doivent jamais être présentés comme un document.
    test('refuse un content-type qui n est pas application/pdf', () {
      final result = EditiqueDocumentMapper.map(
        _response(contentType: 'text/html'),
        EditiqueDocumentType.paymentReceipt,
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });

    test('refuse un content-type absent', () {
      final result = EditiqueDocumentMapper.map(
        _response(contentType: null),
        EditiqueDocumentType.paymentReceipt,
      );
      expect(result.isLeft(), isTrue);
    });

    test('refuse des octets sans signature PDF malgré un bon content-type', () {
      final result = EditiqueDocumentMapper.map(
        _response(bytes: Uint8List.fromList(<int>[0x3C, 0x68, 0x74, 0x6D])),
        EditiqueDocumentType.financialClearance,
      );
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) {});
    });

    test('refuse un corps plus court que la signature', () {
      final result = EditiqueDocumentMapper.map(
        _response(bytes: Uint8List.fromList(<int>[0x25, 0x50])),
        EditiqueDocumentType.notePerception,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // `Headers.value` lève dès qu'un en-tête porte deux valeurs — ce qu'un proxy
  // qui ré-ajoute `Content-Disposition` suffit à provoquer. L'exception serait
  // avalée par le repository et un PDF valide, déjà reçu, deviendrait une
  // « issue inconnue » : le pire verdict sur un RL/QT au numéro déjà brûlé.
  group('EditiqueDocumentMapper.map — en-têtes dupliqués', () {
    HttpResponse<Uint8List> responseWithHeaders(
      Map<String, List<String>> headerMap,
    ) {
      return HttpResponse<Uint8List>(
        _pdfBytes(),
        Response<Uint8List>(
          requestOptions: RequestOptions(path: '/api/v1/whatever'),
          statusCode: 200,
          headers: Headers.fromMap(headerMap),
          data: _pdfBytes(),
        ),
      );
    }

    test('accepte un Content-Disposition en double sans lever', () {
      final result = EditiqueDocumentMapper.map(
        responseWithHeaders(<String, List<String>>{
          Headers.contentTypeHeader: <String>['application/pdf'],
          'content-disposition': <String>[
            'attachment; filename="ETL-QT-2526-000003.pdf"',
            'attachment',
          ],
        }),
        EditiqueDocumentType.financialClearance,
      );

      final document = result.getOrElse(
        () => throw StateError('attendu Right'),
      );
      expect(document.documentNumber, 'ETL-QT-2526-000003');
    });

    test('accepte un Content-Type en double sans lever', () {
      final result = EditiqueDocumentMapper.map(
        responseWithHeaders(<String, List<String>>{
          Headers.contentTypeHeader: <String>[
            'application/pdf',
            'application/pdf',
          ],
        }),
        EditiqueDocumentType.accountStatement,
      );

      expect(result.isRight(), isTrue);
    });
  });
}
