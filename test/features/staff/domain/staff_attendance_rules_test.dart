import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_editor.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_ids.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

ClockTime t(String hhmm) => ClockTime.tryParse(hhmm)!;

void main() {
  final rules = PresenceRules(StaffAttendanceSettings.defaults);
  final editor = StaffAttendanceEditor(rules);
  StaffAttendanceRecord blank() =>
      StaffAttendanceEditor.blank(staffMemberId: 'a-1', workDate: '2026-09-29');

  group('StaffAttendanceIds — vecteurs du serveur (plan v2, Q1)', () {
    const agent = '3f1c2a4e-8b7d-4c61-9e2f-5a0b6c7d8e91';

    test('2026-09-29', () {
      expect(
        StaffAttendanceIds.recordId(
          staffMemberId: agent,
          workDate: '2026-09-29',
        ),
        '18486f49-ef96-538e-86dd-e2d14b397736',
      );
    });

    test('2026-10-01', () {
      expect(
        StaffAttendanceIds.recordId(
          staffMemberId: agent,
          workDate: '2026-10-01',
        ),
        '0fb02174-0bea-5d7e-923f-71ca7ddb5289',
      );
    });
  });

  group('ClockTime', () {
    test('lit HH:mm, ignore les secondes, refuse le reste', () {
      expect(t('07:05').minutes, 425);
      expect(ClockTime.tryParse('08:00:00')!.wire, '08:00');
      expect(ClockTime.tryParse('24:00'), isNull);
      expect(ClockTime.tryParse('7h30'), isNull);
    });
  });

  group('PresenceRules.classify — début 07:30, tolérance 10', () {
    test('jusqu\'à 07:40 inclus : présent', () {
      final result = rules.classify(t('07:40'));
      expect(result.status, PresenceStatus.present);
      expect(result.lateMinutes, 0);
    });

    test('07:52 : en retard de 22 min, comptées depuis le début', () {
      final result = rules.classify(t('07:52'));
      expect(result.status, PresenceStatus.late);
      expect(result.lateMinutes, 22);
    });
  });

  group('PresenceRules.suggestedArrival', () {
    test('présent : l\'heure courante dans la tolérance, sinon le début', () {
      expect(
        rules.suggestedArrival(PresenceStatus.present, t('07:35')),
        t('07:35'),
      );
      expect(
        rules.suggestedArrival(PresenceStatus.present, t('09:00')),
        t('07:30'),
      );
    });

    test(
      'retard : l\'heure courante au-delà, sinon début + tolérance + 15',
      () {
        expect(
          rules.suggestedArrival(PresenceStatus.late, t('09:00')),
          t('09:00'),
        );
        expect(
          rules.suggestedArrival(PresenceStatus.late, t('07:00')),
          t('07:55'),
        );
      },
    );

    test('le cycle n\'atteint jamais « à pointer »', () {
      expect(
        PresenceRules.nextInCycle(PresenceStatus.none),
        PresenceStatus.present,
      );
      expect(
        PresenceRules.nextInCycle(PresenceStatus.present),
        PresenceStatus.late,
      );
      expect(
        PresenceRules.nextInCycle(PresenceStatus.late),
        PresenceStatus.absent,
      );
      expect(
        PresenceRules.nextInCycle(PresenceStatus.absent),
        PresenceStatus.present,
      );
    });
  });

  group('StaffAttendanceEditor — lignes cohérentes', () {
    const justification = StaffAttendanceJustification(
      reason: StaffAbsenceReason.transport,
    );

    test('la ligne vierge porte l\'uuid5 de (agent, jour)', () {
      expect(
        blank().id,
        StaffAttendanceIds.recordId(
          staffMemberId: 'a-1',
          workDate: '2026-09-29',
        ),
      );
    });

    test('absent efface arrivée, départ et heures, garde la justification', () {
      var record = editor.mark(blank(), PresenceStatus.late, t('08:00'));
      record = editor.setDeparture(record, t('12:30'));
      record = editor.setWorked(record, 120);
      record = editor.justify(record, justification);
      record = editor.mark(record, PresenceStatus.absent, t('08:00'));
      expect(record.arrival, isNull);
      expect(record.departure, isNull);
      expect(record.workedMinutes, isNull);
      expect(record.justification, justification);
    });

    test('repasser à l\'heure retire la justification', () {
      var record = editor.setArrival(blank(), t('08:10'));
      record = editor.justify(record, justification);
      expect(record.status, PresenceStatus.late);
      record = editor.setArrival(record, t('07:32'));
      expect(record.status, PresenceStatus.present);
      expect(record.lateMinutes, 0);
      expect(record.justification, isNull);
    });

    test('un départ antérieur à l\'arrivée n\'est pas gardé', () {
      var record = editor.setArrival(blank(), t('07:30'));
      record = editor.setDeparture(record, t('12:30'));
      expect(record.departure, t('12:30'));
      record = editor.setArrival(record, t('13:00'));
      expect(record.departure, isNull);
    });

    test('effacer le départ rend null', () {
      var record = editor.setArrival(blank(), t('07:30'));
      record = editor.setDeparture(record, t('12:30'));
      record = editor.setDeparture(record, null);
      expect(record.departure, isNull);
    });

    test('pas de justification sur un présent, heures bornées à 10 h', () {
      var record = editor.setArrival(blank(), t('07:30'));
      expect(editor.justify(record, justification).justification, isNull);
      record = editor.setWorked(record, 900);
      expect(record.workedMinutes, 600);
    });

    test('effacer remet tout à vide', () {
      var record = editor.setArrival(blank(), t('08:10'));
      record = editor.justify(record, justification);
      record = editor.clear(record);
      expect(record.status, PresenceStatus.none);
      expect(record.arrival, isNull);
      expect(record.lateMinutes, 0);
      expect(record.justification, isNull);
    });
  });
}
