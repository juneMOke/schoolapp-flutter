import 'dart:typed_data';

import 'package:dartz/dartz.dart';
// Ici `Headers` désigne les constantes d'en-têtes de dio, pas l'annotation
// retrofit.
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

/// Transforme une réponse binaire en [EnrollmentEntriesReport], ou refuse.
///
/// **Un 200 ne suffit pas à faire un PDF.** Un portail captif ou un proxy
/// d'entreprise répondent 200 avec du HTML : présentés comme un document, ces
/// octets donnent une visionneuse vide et un fichier illisible, sans le moindre
/// message. Les trois gardes ci-dessous transforment ce silence en
/// [ServerFailure].
///
/// Ce sont les gardes de `TillReportMapper` et de `RelanceListMapper`, non
/// factorisées pour la même raison qu'eux : chacun rend son propre type de
/// pièce. Ce qui était réellement partageable l'est déjà —
/// [ContentDispositionParser].
class EnrollmentEntriesReportMapper {
  const EnrollmentEntriesReportMapper._();

  /// Signature d'un fichier PDF (`%PDF`).
  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  /// Le nom rendu quand le serveur n'annonce rien — il ne devrait jamais
  /// servir, la route posant toujours son `Content-Disposition`.
  static const String _fallbackFileName = 'inscriptions.pdf';

  static Either<Failure, EnrollmentEntriesReport> map(
    HttpResponse<Uint8List> response,
  ) {
    final bytes = response.data;
    final headers = response.response.headers;

    if (bytes.isEmpty) {
      return const Left(ServerFailure('Le registre reçu est vide.'));
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
        ServerFailure('Le registre reçu est illisible ou incomplet.'),
      );
    }

    return Right(
      EnrollmentEntriesReport(
        bytes: bytes,
        fileName:
            ContentDispositionParser.fileName(
              headers.map['content-disposition']?.firstOrNull,
            ) ??
            _fallbackFileName,
      ),
    );
  }
}
