import 'dart:typed_data';

import 'package:dartz/dartz.dart';
// Inverse du data source : ici `Headers` désigne les constantes d'en-têtes de
// dio, pas l'annotation retrofit.
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Transforme une réponse binaire en [EditiqueDocument], ou refuse.
///
/// Un 200 ne suffit pas à faire un document : un portail captif, un proxy
/// d'entreprise ou une passerelle mal configurée répondent 200 avec du HTML.
/// Présenter ces octets comme un PDF donnerait une visionneuse vide et un
/// fichier illisible, sans le moindre message d'erreur. Les trois gardes
/// ci-dessous transforment ce silence en [ServerFailure].
class EditiqueDocumentMapper {
  const EditiqueDocumentMapper._();

  /// Signature d'un fichier PDF (`%PDF`).
  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  static Either<Failure, EditiqueDocument> map(
    HttpResponse<Uint8List> response,
    EditiqueDocumentType type,
  ) {
    final bytes = response.data;
    final headers = response.response.headers;

    if (bytes.isEmpty) {
      return const Left(ServerFailure('Le document reçu est vide.'));
    }

    final contentType = _firstHeader(headers, Headers.contentTypeHeader);
    if (!_isPdfContentType(contentType)) {
      return const Left(
        ServerFailure("La réponse du serveur n'est pas un document PDF."),
      );
    }

    if (!_hasPdfSignature(bytes)) {
      return const Left(
        ServerFailure('Le document reçu est illisible ou incomplet.'),
      );
    }

    final headerFileName = ContentDispositionParser.fileName(
      _firstHeader(headers, 'content-disposition'),
    );
    final documentNumber = ContentDispositionParser.documentNumber(
      headerFileName,
    );

    return Right(
      EditiqueDocument(
        type: type,
        bytes: bytes,
        fileName: headerFileName ?? _fallbackFileName(type),
        documentNumber: documentNumber,
      ),
    );
  }

  /// Lit le premier exemplaire d'un en-tête, sans jamais lever.
  ///
  /// `Headers.value` jette dès qu'un en-tête porte plus d'une valeur — il suffit
  /// d'un proxy ou d'un antivirus réseau qui ré-ajoute `Content-Disposition`.
  /// Levée ici, l'exception serait avalée par le `catch` du repository et
  /// transformerait un PDF déjà reçu, complet et valide, en
  /// `UncertainOutcomeFailure` : le pire verdict possible sur un relevé ou un
  /// quitus, dont le numéro de séquence est alors déjà consommé.
  static String? _firstHeader(Headers headers, String name) {
    final values = headers[name];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  /// `application/pdf`, éventuellement suivi de paramètres (`;charset=…`).
  static bool _isPdfContentType(String? contentType) {
    if (contentType == null) return false;
    return contentType.toLowerCase().trim().startsWith(
      AppConstants.pdfContentType,
    );
  }

  static bool _hasPdfSignature(Uint8List bytes) {
    if (bytes.length < _pdfMagic.length) return false;
    for (var i = 0; i < _pdfMagic.length; i++) {
      if (bytes[i] != _pdfMagic[i]) return false;
    }
    return true;
  }

  /// Nom de repli quand le serveur n'a pas posé de `Content-Disposition`
  /// exploitable — l'en-tête n'est décrit dans aucune route du contrat.
  static String _fallbackFileName(EditiqueDocumentType type) =>
      'document-${type.code.toLowerCase()}.pdf';
}
