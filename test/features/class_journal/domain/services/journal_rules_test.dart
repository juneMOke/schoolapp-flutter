import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_status.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_breaks.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_seance_numbers.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_status_rule.dart';

import '../../journal_fixtures.dart';

void main() {
  final today = DateTime(2026, 10, 14);

  group('statut', () {
    JournalStatus statusOn(DateTime date, {JournalFields? fields, bool? ko}) =>
        JournalStatusRule.of(
          fields == null
              ? null
              : entryOf(
                  coursId: 'c',
                  date: date,
                  slot: 's1',
                  fields: fields,
                  syncState: ko == true
                      ? RecordSyncState.failed
                      : RecordSyncState.pending,
                ),
          date: date,
          today: today,
        );

    test('vierge : à préparer aujourd\'hui et après, non renseignée avant', () {
      expect(statusOn(today), JournalStatus.toPrepare);
      expect(statusOn(DateTime(2026, 10, 15)), JournalStatus.toPrepare);
      expect(statusOn(DateTime(2026, 10, 13)), JournalStatus.missing);
    });

    test('renseignée dès objectif + contenu, même pas encore envoyée', () {
      expect(
        statusOn(
          DateTime(2026, 10, 1),
          fields: const JournalFields(objectif: 'O', contenu: 'C'),
        ),
        JournalStatus.filled,
      );
      expect(
        statusOn(today, fields: const JournalFields(objectif: 'O')),
        JournalStatus.toPrepare,
      );
    });

    test('un refus du serveur prime sur une saisie complète', () {
      expect(
        statusOn(
          today,
          fields: const JournalFields(objectif: 'O', contenu: 'C'),
          ko: true,
        ),
        JournalStatus.rejected,
      );
    });
  });

  group('séance n', () {
    test('rang par date puis créneau, seulement les renseignées', () {
      final d1 = DateTime(2026, 10, 12);
      final d2 = DateTime(2026, 10, 13);
      final numbers = JournalSeanceNumbers.of(
        [
          entryOf(
            id: 'late',
            coursId: 'c',
            date: d2,
            slot: 's1',
            chapitreId: 'ch',
          ),
          entryOf(
            id: 'second',
            coursId: 'c',
            date: d1,
            slot: 's3',
            chapitreId: 'ch',
          ),
          entryOf(
            id: 'first',
            coursId: 'c',
            date: d1,
            slot: 's1',
            chapitreId: 'ch',
          ),
          entryOf(
            id: 'blank',
            coursId: 'c',
            date: d1,
            slot: 's2',
            chapitreId: 'ch',
            fields: const JournalFields(objectif: 'O'),
          ),
          entryOf(id: 'free', coursId: 'c', date: d1, slot: 's4'),
        ],
        slotOrder: {for (final s in kSchoolSlots) s.id: s.order},
      );

      expect(numbers, {'first': 1, 'second': 2, 'late': 3});
    });
  });

  test('séance n : un créneau disparu se range en fin de journée', () {
    final d = DateTime(2026, 10, 12);
    final numbers = JournalSeanceNumbers.of(
      [
        entryOf(
          id: 'retired',
          coursId: 'c',
          date: d,
          slot: 'gone',
          chapitreId: 'ch',
        ),
        entryOf(
          id: 'second',
          coursId: 'c',
          date: d,
          slot: 's2',
          chapitreId: 'ch',
        ),
      ],
      slotOrder: {for (final s in kSchoolSlots) s.id: s.order},
    );

    expect(numbers, {'second': 1, 'retired': 2});
  });

  group('récréation', () {
    test('un trou de la grille de l\'école entre les deux séances', () {
      final pause = JournalBreaks.between(
        kSchoolSlots,
        before: kSchoolSlots[2],
        after: kSchoolSlots[3],
      );

      expect(pause?.start, '10:00:00');
      expect(pause?.end, '10:20:00');
    });

    test('une heure libre du professeur n\'est pas une récréation', () {
      expect(
        JournalBreaks.between(
          kSchoolSlots,
          before: kSchoolSlots[0],
          after: kSchoolSlots[2],
        ),
        isNull,
      );
    });

    test('la pause compte même si une heure libre l\'entoure', () {
      expect(
        JournalBreaks.between(
          kSchoolSlots,
          before: kSchoolSlots[1],
          after: kSchoolSlots[3],
        ),
        isNotNull,
      );
    });
  });
}
