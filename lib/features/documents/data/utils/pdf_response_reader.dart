import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';

/// Lit la réponse binaire d'un PDF servi par le serveur.
///
/// **Un 200 ne suffit pas à faire un PDF** : un portail captif répond 200 avec
/// du HTML. La réponse doit annoncer `application/pdf` ET commencer par
/// `%PDF`. Le nom vient de `Content-Disposition`, le numéro de la pièce de
/// `X-Document-Number` (exposé par le CORS), s'il y en a un.
class PdfResponseReader {
  const PdfResponseReader._();

  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  static Either<Failure, PrintableDocument> read(
    Response<List<int>> response, {
    required String fallbackFileName,
  }) {
    final bytes = Uint8List.fromList(response.data ?? const []);
    if (bytes.isEmpty) {
      return const Left(ServerFailure('Le document reçu est vide.'));
    }
    final contentType = response.headers.value(Headers.contentTypeHeader);
    if (contentType == null ||
        !contentType.toLowerCase().contains(AppConstants.pdfContentType)) {
      return const Left(
        ServerFailure("La réponse du serveur n'est pas un document PDF."),
      );
    }
    for (var i = 0; i < _pdfMagic.length; i++) {
      if (bytes.length <= i || bytes[i] != _pdfMagic[i]) {
        return const Left(
          ServerFailure('Le document reçu est illisible ou incomplet.'),
        );
      }
    }
    final fileName =
        ContentDispositionParser.fileName(
          response.headers.value('content-disposition'),
        ) ??
        fallbackFileName;
    final number = response.headers.value('x-document-number')?.trim();
    return Right(
      PrintableDocument(
        bytes: bytes,
        fileName: fileName,
        reference: number == null || number.isEmpty ? null : number,
      ),
    );
  }
}
