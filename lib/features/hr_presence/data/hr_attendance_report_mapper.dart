import 'dart:typed_data';

import 'package:dartz/dartz.dart';
// Ici `Headers` désigne les constantes d'en-têtes de dio, pas l'annotation
// retrofit.
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';

/// Lit la réponse de `GET /hr/attendance-stats.pdf` : un 200 dont le corps
/// n'est pas un PDF est une erreur, pas un document vide.
///
/// La même lecture que les autres rapports servis (liste du personnel,
/// caisse, recouvrement) : chacun garde la sienne, avec son nom par défaut.
class HrAttendanceReportMapper {
  const HrAttendanceReportMapper._();

  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  static const String _fallbackFileName = 'assiduite-personnel.pdf';

  static Either<Failure, HrAttendanceReport> map(
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
      HrAttendanceReport(
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
