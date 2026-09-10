import 'dart:typed_data';

import 'package:dartz/dartz.dart';
// Ici `Headers` désigne les constantes d'en-têtes de dio, pas l'annotation
// retrofit.
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_report.dart';

/// Transforme une réponse binaire en [TillReport], ou refuse.
///
/// **Un 200 ne suffit pas à faire un PDF.** Un portail captif, un proxy
/// d'entreprise ou une passerelle mal configurée répondent 200 avec du HTML :
/// présentés comme un document, ces octets donnent une visionneuse vide et un
/// fichier illisible, sans le moindre message. Les trois gardes ci-dessous
/// transforment ce silence en [ServerFailure].
///
/// Ce sont les mêmes gardes que `EditiqueDocumentMapper`, et elles ne sont pas
/// factorisées avec lui **parce qu'il map vers autre chose** : son résultat
/// porte un type de pièce, un numéro scellé et un identifiant d'archive, dont
/// aucun n'existe ici — ce rapport n'est pas archivé. Ce qui était réellement
/// partageable l'est : [ContentDispositionParser].
class TillReportMapper {
  const TillReportMapper._();

  /// Signature d'un fichier PDF (`%PDF`).
  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  /// Le nom rendu quand le serveur n'annonce rien — il ne devrait jamais
  /// servir, la route posant toujours son `Content-Disposition`.
  static const String _fallbackFileName = 'encaissements.pdf';

  static Either<Failure, TillReport> map(HttpResponse<Uint8List> response) {
    final bytes = response.data;
    final headers = response.response.headers;

    if (bytes.isEmpty) {
      return const Left(ServerFailure('Le rapport reçu est vide.'));
    }

    final contentType = headers.map[Headers.contentTypeHeader]?.firstOrNull
        ?.toLowerCase();
    if (contentType == null ||
        !contentType.contains(AppConstants.pdfContentType)) {
      return const Left(
        ServerFailure("La réponse du serveur n'est pas un document PDF."),
      );
    }

    if (bytes.length < _pdfMagic.length ||
        !_pdfMagic.asMap().entries.every((e) => bytes[e.key] == e.value)) {
      return const Left(
        ServerFailure('Le rapport reçu est illisible ou incomplet.'),
      );
    }

    final fileName = ContentDispositionParser.fileName(
      headers.map['content-disposition']?.firstOrNull,
    );

    return Right(
      TillReport(bytes: bytes, fileName: fileName ?? _fallbackFileName),
    );
  }
}
