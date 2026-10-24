import 'dart:typed_data';

import 'package:dartz/dartz.dart';
// Ici `Headers` désigne les constantes d'en-têtes de dio, pas l'annotation
// retrofit.
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';

/// Transforme une réponse binaire en [HrStaffListReport], ou refuse.
///
/// **Un 200 ne suffit pas à faire un PDF** : un portail captif répond 200 avec
/// du HTML. Les trois gardes de `BoutiqueSalesReportMapper`.
class HrStaffListReportMapper {
  const HrStaffListReportMapper._();

  /// Signature d'un fichier PDF (`%PDF`).
  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  /// Le nom rendu quand le serveur n'annonce rien — la route pose toujours
  /// son `Content-Disposition`.
  static const String _fallbackFileName = 'personnel.pdf';

  static Either<Failure, HrStaffListReport> map(
    HttpResponse<Uint8List> response,
  ) {
    final bytes = response.data;
    final headers = response.response.headers;

    if (bytes.isEmpty) {
      return const Left(ServerFailure('Le document reçu est vide.'));
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
        ServerFailure('Le document reçu est illisible ou incomplet.'),
      );
    }

    return Right(
      HrStaffListReport(
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
