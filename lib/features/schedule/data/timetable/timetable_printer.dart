import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/documents/data/utils/editique_failure_mapper.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';

/// Imprimer l'emploi du temps d'une classe (R16, O7) : la **version publiée**,
/// composée par l'éditique du serveur (EDT-10) — une pièce `ET` numérotée,
/// jamais un rendu de l'appareil. En ligne seulement ; un brouillon ne
/// s'imprime jamais.
class TimetablePrinter {
  final Dio _dio;
  final Map<String, dynamic> _requiredAuth;

  const TimetablePrinter({
    required Dio dio,
    required Map<String, dynamic> requiredAuth,
  }) : _dio = dio,
       _requiredAuth = requiredAuth;

  /// Signature d'un fichier PDF (`%PDF`).
  static const List<int> _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  Future<Either<Failure, PrintableDocument>> print(
    ClassTimetableView view,
  ) async {
    final version = view.header?.publishedVersion;
    if (version == null) {
      return const Left(TimetableRefusalFailure('TIMETABLE_NOT_PUBLISHED'));
    }
    try {
      final response = await _dio.get<List<int>>(
        AppConstants.timetablePdfEndpoint(view.classroom.classroomId),
        queryParameters: {'version': version},
        options: Options(
          extra: _requiredAuth,
          responseType: ResponseType.bytes,
          headers: {'Accept': AppConstants.pdfAcceptHeader},
          receiveTimeout: AppConstants.timetablePdfTimeout,
        ),
      );
      return _document(response, fallback: '${view.classroom.name}.pdf');
    } on DioException catch (e) {
      final code = ApiErrorParser.detailCodeOf(e.response);
      if (code != null && code.startsWith('TIMETABLE_')) {
        return Left(TimetableRefusalFailure(code));
      }
      return Left(EditiqueFailureMapper.fromDioException(e));
    } catch (_) {
      return const Left(ServerFailure('Unexpected error occurred'));
    }
  }

  /// **Un 200 ne suffit pas à faire un PDF** : un portail captif répond 200
  /// avec du HTML. Mêmes gardes que les autres pièces.
  static Either<Failure, PrintableDocument> _document(
    Response<List<int>> response, {
    required String fallback,
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
        fallback;
    // Le numéro de la pièce (`ETL-ET-2627-000012`), exposé par le CORS ;
    // pas d'identifiant : la pièce n'est pas archivée.
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
