import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_printer.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions o) respond;
  RequestOptions? sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    sent = o;
    return respond(o);
  }

  @override
  void close({bool force = false}) {}
}

ClassTimetableView _view({int? version = 3}) => ClassTimetableView(
  classroom: const TimetableClassOption(
    classroomId: 'c7a',
    name: '7e A',
    cycleCode: 'SEC',
    cycleName: 'Sec',
    levelCode: 'L7',
    levelName: '7e',
  ),
  grid: null,
  slots: const [],
  header: ClassTimetableHeader(
    id: 'h',
    classroomId: 'c7a',
    academicYearId: 'y',
    revision: 1,
    publishedVersion: version,
  ),
  published: const [],
  draft: const [],
  programme: const [],
  othersKnown: true,
);

void main() {
  TimetablePrinter printer(_Adapter adapter) => TimetablePrinter(
    dio: Dio()..httpClientAdapter = adapter,
    requiredAuth: const {},
  );

  test('la pièce ET de la version publiée, avec son nom de fichier', () async {
    final adapter = _Adapter(
      (_) => ResponseBody.fromBytes(
        utf8.encode('%PDF-1.7 page'),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/pdf'],
          'content-disposition': [
            'attachment; filename="emploi-du-temps-7e-A-v3.pdf"',
          ],
          'x-document-number': ['ETL-ET-2627-000012'],
        },
      ),
    );
    final result = await printer(adapter).print(_view());
    expect(adapter.sent!.path, '/api/v1/schedule/classrooms/c7a/timetable.pdf');
    expect(adapter.sent!.queryParameters, {'version': 3});
    final document = result.toOption().toNullable()!;
    expect(document.fileName, 'emploi-du-temps-7e-A-v3.pdf');
    expect(document.reference, 'ETL-ET-2627-000012');
  });

  test('un 200 en HTML (portail captif) n’est pas une pièce', () async {
    final adapter = _Adapter(
      (_) => ResponseBody.fromString(
        '<html>connexion</html>',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      ),
    );
    final result = await printer(adapter).print(_view());
    expect(result.swap().toOption().toNullable(), isA<ServerFailure>());
  });

  test('une version dépassée revient en refus nommé (422)', () async {
    final adapter = _Adapter(
      (_) => ResponseBody.fromString(
        jsonEncode({'detailCode': 'TIMETABLE_VERSION_CHANGED'}),
        422,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    final result = await printer(adapter).print(_view());
    final failure = result.swap().toOption().toNullable();
    expect(failure, isA<TimetableRefusalFailure>());
    expect(
      (failure! as TimetableRefusalFailure).code,
      'TIMETABLE_VERSION_CHANGED',
    );
  });

  test('une classe jamais publiée ne demande rien au serveur', () async {
    final adapter = _Adapter((_) => throw StateError('aucun appel attendu'));
    final result = await printer(adapter).print(_view(version: null));
    expect(adapter.sent, isNull);
    expect(
      (result.swap().toOption().toNullable()! as TimetableRefusalFailure).code,
      'TIMETABLE_NOT_PUBLISHED',
    );
  });
}
