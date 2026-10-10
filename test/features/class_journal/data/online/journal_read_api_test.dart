import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/data/online/journal_read_api.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Object body;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('la journée : lignes, créneau disparu, séance écrite ou non', () async {
    final adapter = _StubAdapter({
      'teacherId': 't',
      'date': '2026-10-14',
      'lignes': [
        {
          'coursId': 'c-1',
          'classroomId': 'r-1',
          'branche': 'Mathématiques',
          'classroomLabel': '7e A',
          'inTimetable': true,
          'creneau': {
            'id': 's-1',
            'slotOrder': 1,
            'startTime': '07:30:00',
            'endTime': '08:20:00',
          },
          'entry': null,
        },
        {
          'coursId': 'c-2',
          'classroomId': 'r-2',
          'branche': null,
          'classroomLabel': null,
          'inTimetable': false,
          'creneau': null,
          'entry': {
            'id': 'e',
            'coursId': 'c-2',
            'date': '2026-10-14',
            'timeSlotId': 's-gone',
            'objectif': 'Calculer',
            'contenu': 'Aires',
            'clientUpdatedAt': '2026-10-14T08:00:00Z',
            'serverUpdatedAt': '2026-10-14T08:00:01Z',
          },
        },
        {'classroomId': 'sans cours'},
      ],
    });
    final api = JournalReadApi(Dio()..httpClientAdapter = adapter);

    final lines = await api.dayOf(const {}, 't', DateTime(2026, 10, 14));

    expect(adapter.captured?.queryParameters, {
      'teacherId': 't',
      'date': '2026-10-14',
    });
    expect(lines, hasLength(2));
    expect(lines.first.slot?.order, 1);
    expect(lines.first.entry, isNull);
    expect(lines.last.slot, isNull);
    expect(lines.last.timeSlotId, 's-gone');
    expect(lines.last.inTimetable, isFalse);
    expect(lines.last.entry?.isFilled, isTrue);
    expect(lines.last.subjectLabel, isEmpty);
  });

  test('les enseignants : NOM Post-nom Prénom', () async {
    final api = JournalReadApi(
      Dio()
        ..httpClientAdapter = _StubAdapter([
          {
            'id': 't-1',
            'lastName': 'Mokili',
            'middleName': 'Bolamba',
            'firstName': 'Jean',
          },
          {'lastName': 'Sans id'},
        ]),
    );

    final teachers = await api.teachers(const {});

    expect(teachers.single.displayName, 'Mokili Bolamba Jean');
  });
}
