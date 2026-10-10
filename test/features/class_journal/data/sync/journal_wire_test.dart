import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';

void main() {
  const wire = {
    'id': 'e-1',
    'coursId': 'c-1',
    'date': '2026-10-12',
    'timeSlotId': 's-1',
    'chapitreId': 'ch-1',
    'objectif': '  Calculer  ',
    'contenu': 'Aires',
    'clientUpdatedAt': '2026-10-12T09:00:00+01:00',
  };

  test('lit une entrée ; les champs saisis ne sont jamais rognés', () {
    final dto = JournalEntryDto.tryParse(wire)!;

    expect(dto.date, '2026-10-12');
    expect(dto.fields.objectif, '  Calculer  ');
    expect(dto.fields.cb, isEmpty);
    expect(dto.clientUpdatedAt, '2026-10-12T08:00:00.000Z');
  });

  test('sans identité ou avec un jour mal formé, rien', () {
    expect(JournalEntryDto.tryParse({...wire, 'date': '12/10/2026'}), isNull);
    expect(JournalEntryDto.tryParse({...wire}..remove('timeSlotId')), isNull);
  });

  test('accusé SUPERSEDED : l\'entrée retenue est la sienne', () {
    final ack = JournalEntryAck.fromJson({
      'entry': wire,
      'lwwOutcome': 'SUPERSEDED',
    });

    expect(ack.superseded, isTrue);
    expect(() => JournalEntryAck.fromJson({}), throwsFormatException);
  });

  test('le payload d\'outbox fait l\'aller-retour, et se détache', () {
    final payload = JournalEntryPayload.of(
      JournalEntry(
        id: 'e-1',
        coursId: 'c-1',
        date: DateTime(2026, 10, 2),
        timeSlotId: 's-1',
        chapitreId: 'ch-1',
        fields: const JournalFields(objectif: 'O', contenu: 'C'),
        clientUpdatedAt: DateTime.utc(2026, 10, 2, 8),
      ),
    );

    final read = JournalEntryPayload.tryParse(payload.toJson())!;
    expect(read.entry['date'], '2026-10-02');
    expect(read.clientUpdatedAt, '2026-10-02T08:00:00.000Z');
    expect(read.chapitreId, 'ch-1');
    expect(read.detached().chapitreId, isNull);
    expect(read.detached().entry['objectif'], 'O');
  });
}
