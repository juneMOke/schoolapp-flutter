import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';

void main() {
  test('renseignée = objectif ET contenu, espaces ignorés', () {
    expect(
      const JournalFields(objectif: 'Calculer', contenu: 'Aires').isFilled,
      isTrue,
    );
    expect(const JournalFields(objectif: 'Calculer').isFilled, isFalse);
    expect(
      const JournalFields(objectif: '  ', contenu: 'Aires').isFilled,
      isFalse,
    );
  });

  test('vide = aucun des sept champs', () {
    expect(JournalFields.empty.isBlank, isTrue);
    expect(const JournalFields(observation: ' ').isBlank, isTrue);
    expect(const JournalFields(evaluation: 'Exercice 1').isBlank, isFalse);
  });

  test('une entrée vidée = champs vides ET sans chapitre', () {
    JournalEntry entry({String? chapitreId}) => JournalEntry(
      id: 'e',
      coursId: 'c',
      date: DateTime(2026, 10, 12),
      timeSlotId: 's',
      chapitreId: chapitreId,
    );

    expect(entry().isBlank, isTrue);
    expect(entry(chapitreId: 'ch').isBlank, isFalse);
  });
}
