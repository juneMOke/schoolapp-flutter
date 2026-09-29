import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_agent_month.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_recap.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';

StaffMember member(
  String id,
  String lastName, {
  StaffContractKind kind = StaffContractKind.permanent,
  StaffPayMode? payMode,
}) => StaffMember(
  id: id,
  lastName: lastName,
  firstName: 'Prénom',
  category: StaffCategory.teacher,
  syncState: StaffSyncState.synced,
  contracts: [
    StaffContractPeriod(
      contractId: 'c-$id',
      kind: kind,
      payMode: payMode,
      effectiveFrom: '2026-01-01',
    ),
  ],
);

StaffAttendanceRecord record(
  String memberId,
  String day,
  StaffAttendanceStatus status, {
  int late = 0,
  int? worked,
  bool justified = false,
  StaffSyncState sync = StaffSyncState.synced,
}) => StaffAttendanceRecord(
  id: '$memberId-$day',
  staffMemberId: memberId,
  workDate: day,
  status: status,
  lateMinutes: late,
  workedMinutes: worked,
  justification: justified
      ? const StaffAttendanceJustification(reason: StaffAbsenceReason.illness)
      : null,
  syncState: sync,
);

void main() {
  group('StaffWorkCalendar', () {
    test('lundi → vendredi, jusqu\'à aujourd\'hui', () {
      final days = StaffWorkCalendar.workDaysOf('2026-09', today: '2026-09-09');
      expect(days, [
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
        '2026-09-07',
        '2026-09-08',
        '2026-09-09',
      ]);
    });

    test('borné par l\'année scolaire ; hors année = vacances', () {
      const year = StaffSchoolYear(start: '2026-09-07', end: '2027-07-02');
      expect(
        StaffWorkCalendar.workDaysOf(
          '2026-09',
          today: '2026-09-09',
          year: year,
        ),
        ['2026-09-07', '2026-09-08', '2026-09-09'],
      );
      expect(
        StaffWorkCalendar.workDaysOf(
          '2027-08',
          today: '2027-08-31',
          year: year,
        ),
        isEmpty,
      );
    });

    test('le jour ouvré suivant saute le week-end', () {
      expect(StaffWorkCalendar.stepWorkDay('2026-09-04', 1), '2026-09-07');
      expect(StaffWorkCalendar.stepWorkDay('2026-09-07', -1), '2026-09-04');
      expect(StaffWorkCalendar.addMonths('2026-12', 1), '2027-01');
    });
  });

  final alpha = member('a', 'Alpha');
  final vac = member(
    'v',
    'Vacataire',
    kind: StaffContractKind.vacataire,
    payMode: StaffPayMode.hourly,
  );
  final snapshot = StaffAttendanceSnapshot(
    members: [alpha, vac],
    records: {
      'a': {
        '2026-09-01': record('a', '2026-09-01', StaffAttendanceStatus.present),
        '2026-09-02': record(
          'a',
          '2026-09-02',
          StaffAttendanceStatus.late,
          late: 22,
        ),
        '2026-09-03': record(
          'a',
          '2026-09-03',
          StaffAttendanceStatus.absent,
          justified: true,
        ),
        '2026-09-04': record(
          'a',
          '2026-09-04',
          StaffAttendanceStatus.absent,
          sync: StaffSyncState.pending,
        ),
      },
      'v': {
        '2026-09-02': record(
          'v',
          '2026-09-02',
          StaffAttendanceStatus.present,
          worked: 90,
        ),
      },
    },
    locks: {
      StaffAttendanceSnapshot.lockKey(
        StaffAttendanceLockKind.day,
        '2026-09-02',
      ): const StaffAttendanceLock(
        kind: StaffAttendanceLockKind.day,
        periodStart: '2026-09-02',
        locked: true,
      ),
    },
    settings: StaffAttendanceSettings.defaults,
    hasEverSynced: true,
    contractRates: const {'c-v': Money(500, 'USD')},
  );

  group('StaffMonthRecap — une seule façon de compter', () {
    final recap = StaffMonthRecap.build(
      snapshot,
      month: '2026-09',
      today: '2026-09-07',
      query: StaffRecapQuery.none,
    );
    final alphaRow = recap.all.firstWhere((row) => row.member.id == 'a');
    final vacRow = recap.all.firstWhere((row) => row.member.id == 'v');

    test('présences, retards, absences J/NJ, non pointés', () {
      final stats = alphaRow.stats;
      expect(stats.workDays, 5);
      expect(stats.present, 2);
      expect(stats.late, 1);
      expect(stats.lateMinutes, 22);
      expect(stats.lateUnjustified, 1);
      expect(stats.absentJustified, 1);
      expect(stats.absentUnjustified, 1);
      expect(stats.notMarked, 1);
      expect(alphaRow.sync, StaffSyncState.pending);
    });

    test(
      'un vacataire à l\'heure n\'a pas de non pointés, et a un montant',
      () {
        expect(vacRow.stats.isHourly, isTrue);
        expect(vacRow.stats.notMarked, 0);
        expect(vacRow.stats.workedMinutes, 90);
        expect(vacRow.stats.amount, const Money(750, 'USD'));
        expect(recap.amountByCurrency, {'USD': 750});
      },
    );

    test('taux de présence hors vacataires à l\'heure', () {
      expect(recap.presenceRate, closeTo(2 / 5, 1e-9));
    });

    test('filtre de contrat', () {
      final filtered = StaffMonthRecap.build(
        snapshot,
        month: '2026-09',
        today: '2026-09-07',
        query: StaffRecapQuery.none.toggleContract(
          StaffContractFilter.vacataire,
        ),
      );
      expect(filtered.rows.map((row) => row.member.id), ['v']);
    });
  });

  group('clôture et contrats, jour par jour', () {
    test('un mois clos compte ses non-pointés comme présents', () {
      final closed = StaffAttendanceSnapshot(
        members: snapshot.members,
        records: snapshot.records,
        locks: {
          StaffAttendanceSnapshot.lockKey(
            StaffAttendanceLockKind.month,
            '2026-09-01',
          ): const StaffAttendanceLock(
            kind: StaffAttendanceLockKind.month,
            periodStart: '2026-09-01',
            locked: true,
          ),
        },
        settings: StaffAttendanceSettings.defaults,
        hasEverSynced: true,
      );
      final row = StaffMonthRecap.build(
        closed,
        month: '2026-09',
        today: '2026-09-07',
        query: StaffRecapQuery.none,
      ).all.firstWhere((r) => r.member.id == 'a');

      expect(row.stats.notMarked, 0);
      expect(row.stats.present, 3);
    });

    test(
      'un jour sans contrat ne compte pas, et n\'est pas marqué d\'office',
      () {
        const newcomer = StaffMember(
          id: 'n',
          lastName: 'Nouveau',
          firstName: 'Prénom',
          category: StaffCategory.teacher,
          syncState: StaffSyncState.synced,
          contracts: [
            StaffContractPeriod(
              contractId: 'c-n',
              kind: StaffContractKind.permanent,
              effectiveFrom: '2026-09-07',
            ),
          ],
        );
        final withNewcomer = StaffAttendanceSnapshot(
          members: const [newcomer],
          records: const {},
          locks: const {},
          settings: StaffAttendanceSettings.defaults,
          hasEverSynced: true,
        );

        final stats = StaffMonthRecap.build(
          withNewcomer,
          month: '2026-09',
          today: '2026-09-08',
          query: StaffRecapQuery.none,
        ).all.single.stats;
        final before = StaffDayRegister.build(
          withNewcomer,
          day: '2026-09-04',
          query: StaffDayQuery.none,
        );

        expect(stats.workDays, 2);
        expect(stats.notMarked, 2);
        expect(before.unmarked, isEmpty);
      },
    );
  });

  group('StaffDayRegister', () {
    test('compte par statut, repère les incidents et le jour validé', () {
      final register = StaffDayRegister.build(
        snapshot,
        day: '2026-09-02',
        query: StaffDayQuery.none,
      );
      expect(register.count(StaffAttendanceStatus.late), 1);
      expect(register.count(StaffAttendanceStatus.present), 1);
      expect(register.toJustify, 1);
      expect(register.frozen, isTrue);
      expect(register.showsHours, isTrue);
    });

    test('filtre « à pointer »', () {
      final register = StaffDayRegister.build(
        snapshot,
        day: '2026-09-07',
        query: const StaffDayQuery(status: StaffAttendanceStatus.none),
      );
      expect(register.rows, hasLength(2));
      expect(register.unmarked, hasLength(2));
      expect(register.frozen, isFalse);
    });
  });

  group('StaffAgentMonth', () {
    test('calendrier aligné sur le lundi et incidents du mois', () {
      final month = StaffAgentMonth.build(
        snapshot,
        member: alpha,
        month: '2026-09',
        today: '2026-09-07',
      );
      // Le 1er septembre 2026 est un mardi : une case vide devant.
      expect(month.calendar.first, isNull);
      expect(month.calendar[1]!.day, '2026-09-01');
      expect(month.calendar.last!.day, '2026-09-30');
      expect(month.calendar.last!.upcoming, isTrue);
      expect(month.incidents.map((r) => r.workDate), [
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
      ]);
    });
  });
}
