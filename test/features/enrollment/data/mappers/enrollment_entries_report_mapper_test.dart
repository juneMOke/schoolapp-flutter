import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/data/mappers/enrollment_entries_report_mapper.dart';

/// Octets minimaux acceptés comme PDF : signature `%PDF` + un peu de contenu.
Uint8List _pdfBytes() =>
    Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);

HttpResponse<Uint8List> _response({
  Uint8List? bytes,
  String? contentType = 'application/pdf',
  String? contentDisposition,
}) {
  final headerMap = <String, List<String>>{};
  if (contentType != null) {
    headerMap[Headers.contentTypeHeader] = <String>[contentType];
  }
  if (contentDisposition != null) {
    headerMap['content-disposition'] = <String>[contentDisposition];
  }

  final data = bytes ?? _pdfBytes();
  return HttpResponse<Uint8List>(
    data,
    Response<Uint8List>(
      requestOptions: RequestOptions(
        path: '/api/v1/enrollment-stats/entries.pdf',
      ),
      statusCode: 200,
      headers: Headers.fromMap(headerMap),
      data: data,
    ),
  );
}

/// **Un 200 ne suffit pas à faire un PDF.**
void main() {
  test('le nom du serveur est repris tel quel', () {
    final result = EnrollmentEntriesReportMapper.map(
      _response(
        contentDisposition:
            'attachment; filename="inscriptions-2026-09-01_2026-09-07.pdf"',
      ),
    );

    // Il porte les bornes réellement retenues : le réécrire ferait s'écraser
    // deux registres de deux semaines dans le dossier de téléchargement.
    expect(
      result.getOrElse(() => throw StateError('attendu')).fileName,
      'inscriptions-2026-09-01_2026-09-07.pdf',
    );
  });

  test('sans en-tête de nom, un repli lisible plutôt qu’un vide', () {
    final result = EnrollmentEntriesReportMapper.map(_response());

    expect(
      result.getOrElse(() => throw StateError('attendu')).fileName,
      'inscriptions.pdf',
    );
  });

  test('un corps vide est refusé', () {
    final result = EnrollmentEntriesReportMapper.map(
      _response(bytes: Uint8List(0)),
    );

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('du HTML servi en 200 est refusé — portail captif', () {
    final result = EnrollmentEntriesReportMapper.map(
      _response(contentType: 'text/html; charset=utf-8'),
    );

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('un type PDF annoncé sans la signature %PDF est refusé', () {
    final result = EnrollmentEntriesReportMapper.map(
      _response(bytes: Uint8List.fromList(utf8.encode('<html></html>'))),
    );

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('sans type de contenu du tout, refusé', () {
    final result = EnrollmentEntriesReportMapper.map(
      _response(contentType: null),
    );

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });
}
