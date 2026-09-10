import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/mappers/till_report_mapper.dart';

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
        path: '/api/v1/finance-stats/till/receipts.pdf',
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
    final result = TillReportMapper.map(
      _response(
        contentDisposition:
            'attachment; filename="encaissements-USD-2026-09-01_2026-09-30.pdf"',
      ),
    );

    // Il porte les bornes réellement retenues : le réécrire ferait s'écraser
    // deux rapports de deux périodes dans le dossier de téléchargement.
    expect(
      result.getOrElse(() => throw StateError('attendu')).fileName,
      'encaissements-USD-2026-09-01_2026-09-30.pdf',
    );
  });

  test('sans en-tête de nom, un repli lisible plutôt qu’un vide', () {
    final result = TillReportMapper.map(_response());

    expect(
      result.getOrElse(() => throw StateError('attendu')).fileName,
      'encaissements.pdf',
    );
  });

  test('une page HTML rendue en 200 est refusée, pas présentée', () {
    // Le cas réel : portail captif, proxy d'entreprise, passerelle mal
    // configurée. Ces octets présentés comme un document donnent une
    // visionneuse vide, sans le moindre message.
    final result = TillReportMapper.map(
      _response(contentType: 'text/html; charset=utf-8'),
    );

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('refus'));
  });

  test('un corps qui n’a pas la signature %PDF est refusé', () {
    final result = TillReportMapper.map(
      // Content-Type juste, contenu faux : c'est la seconde garde qui l'attrape.
      _response(bytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5])),
    );

    expect(result.isLeft(), isTrue);
  });

  test('un corps vide est refusé', () {
    final result = TillReportMapper.map(_response(bytes: Uint8List(0)));

    expect(result.isLeft(), isTrue);
  });

  test('un corps plus court que la signature ne fait pas déborder la garde', () {
    // Trois octets : la comparaison octet à octet lirait hors des bornes si la
    // longueur n'était pas testée d'abord.
    final result = TillReportMapper.map(
      _response(bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44])),
    );

    expect(result.isLeft(), isTrue);
  });
}
