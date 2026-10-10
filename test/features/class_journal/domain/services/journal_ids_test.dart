import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_ids.dart';

void main() {
  test('rejoue le vecteur du contrat back (Q1)', () {
    final id = JournalIds.entryId(
      JournalSeanceKey(
        coursId: '3f6c2a1e-8b4d-4c7a-9e21-5d0b7a4c9f13',
        date: DateTime(2026, 10, 12),
        timeSlotId: 'a7e4c1d2-5b3f-4e8a-9c60-1f2d3e4b5a69',
      ),
    );

    expect(id, '8a44a419-2067-5460-a6df-8e58f5b70373');
  });

  test('un créneau en majuscules donne le même id', () {
    String idOf(String slot) => JournalIds.entryId(
      JournalSeanceKey(
        coursId: '3f6c2a1e-8b4d-4c7a-9e21-5d0b7a4c9f13',
        date: DateTime(2026, 10, 12),
        timeSlotId: slot,
      ),
    );

    expect(
      idOf('A7E4C1D2-5B3F-4E8A-9C60-1F2D3E4B5A69'),
      idOf('a7e4c1d2-5b3f-4e8a-9c60-1f2d3e4b5a69'),
    );
  });
}
