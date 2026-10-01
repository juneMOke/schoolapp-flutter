import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark_editor.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

ClockTime at(int h, int m) => ClockTime.fromMinutes(h * 60 + m);

void main() {
  // 07:30, tolérance 10 min : à l'heure jusqu'à 07:40.
  final editor = PresenceMarkEditor(PresenceRules(PresenceSchedule.defaults));
  const sick = PresenceJustification<String>(reason: 'MALADIE');

  group('PresenceMarkEditor', () {
    test('une arrivée après la tolérance classe en retard depuis le début', () {
      final mark = editor.setArrival(
        const PresenceMark<String>.none(),
        at(7, 48),
      );
      expect(mark.status, PresenceStatus.late);
      expect(mark.lateMinutes, 18);
      expect(mark.needsJustification, isTrue);
    });

    test('repasser à l\'heure retire la justification devenue sans objet', () {
      final late = editor.justify(
        editor.setArrival(const PresenceMark<String>.none(), at(7, 50)),
        sick,
      );
      expect(late.justification, sick);
      final onTime = editor.setArrival(late, at(7, 35));
      expect(onTime.status, PresenceStatus.present);
      expect(onTime.justification, isNull);
    });

    test('absent efface l\'heure mais garde la justification', () {
      final late = editor.justify(
        editor.setArrival(const PresenceMark<String>.none(), at(8, 0)),
        sick,
      );
      final absent = editor.mark(late, PresenceStatus.absent, at(9, 0));
      expect(absent.arrival, isNull);
      expect(absent.lateMinutes, 0);
      expect(absent.justification, sick);
    });

    test('présent à 07:00 propose l\'heure courante, à 09:00 le début', () {
      expect(
        editor
            .mark(
              const PresenceMark<String>.none(),
              PresenceStatus.present,
              at(7, 0),
            )
            .arrival,
        at(7, 0),
      );
      expect(
        editor
            .mark(
              const PresenceMark<String>.none(),
              PresenceStatus.present,
              at(9, 0),
            )
            .arrival,
        at(7, 30),
      );
    });

    test('un présent ne se justifie pas', () {
      final present = editor.setArrival(
        const PresenceMark<String>.none(),
        at(7, 30),
      );
      expect(editor.justify(present, sick), present);
    });

    test('effacer remet tout à vide', () {
      final late = editor.setArrival(
        const PresenceMark<String>.none(),
        at(8, 0),
      );
      expect(editor.clear(late), const PresenceMark<String>.none());
    });

    test('un départ avant l\'arrivée ne change rien', () {
      final present = editor.setArrival(
        const PresenceMark<String>.none(),
        at(7, 30),
      );
      final withDeparture = editor.setDeparture(present, at(12, 0));
      expect(editor.setDeparture(withDeparture, at(7, 0)), withDeparture);
      expect(editor.setDeparture(withDeparture, null).departure, isNull);
    });
  });

  group('presenceCalendar', () {
    test('cases vides avant le premier jour, statut seulement hors avenir', () {
      final days = presenceCalendar(
        weekdays: const ['2026-09-02', '2026-09-03'],
        firstWeekday: DateTime.wednesday,
        upcoming: (day) => day == '2026-09-03',
        statusOf: (_) => PresenceStatus.absent,
      );
      expect(days.take(2), [null, null]);
      expect(days[2]!.status, PresenceStatus.absent);
      expect(days[3]!.status, PresenceStatus.none);
      expect(days[3]!.upcoming, isTrue);
    });
  });
}
