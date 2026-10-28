import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/attendance_summary_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/attendance_summary_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

const _school = 's-1';

Map<String, dynamic> _line(String member, {int net = 27500}) => {
  'staffMemberId': member,
  'contractId': 'c-1',
  'contractKind': 'PERMANENT',
  'currency': 'USD',
  'base': {'amountInCents': 35000},
  'overtime': {'minutes': 240, 'rateInCents': 250, 'amountInCents': 1000},
  'allowance': {'children': 3, 'amountInCents': 1500},
  'grossInCents': 37500,
  'advances': [
    {
      'advanceId': 'a-1',
      'rank': 1,
      'dueInCents': 10000,
      'takenInCents': 10000,
      'carriedInCents': 0,
    },
  ],
  'netInCents': net,
  'attendance': {'month': '2026-09', 'unjustifiedAbsences': 1, 'lates': 2},
};

PayrollDto _payroll(String status, {List<Map<String, dynamic>>? lines}) =>
    PayrollDto.tryParse({
      'id': 'p-10',
      'month': '2026-10',
      'status': status,
      'validationGestureId': status == 'VALIDATED' ? 'g-v' : null,
      'variables': [
        {
          'staffMemberId': 'm-1',
          'overtimeMinutes': 240,
          'clientUpdatedAt': '2026-10-20T09:00:00Z',
        },
      ],
      'gestures': [
        {
          'gestureId': 'g-v',
          'kind': 'VALIDATE',
          'by': 'Mbuyi Kalombo Jean-Pierre',
          'at': '2026-10-26T10:00:00Z',
        },
      ],
      'lines': ?lines,
    })!;

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  group('paies descendues', () {
    test('une paie validée garde ses lignes figées, relues entières', () async {
      final dao = PayrollDao(db);

      await dao.apply(
        [
          _payroll('VALIDATED', lines: [_line('m-1')]),
        ],
        schoolId: _school,
        nowMs: 1,
      );

      final header = (await dao.headers(_school))['2026-10']!;
      final line = (await dao.frozenLines(_school))['2026-10']!.single;
      expect(header.status, PayrollStatus.validated);
      expect(header.validationGestureId, 'g-v');
      expect(line.netInCents, 27500);
      expect(line.advanceInCents, 10000);
      expect(line.attendance.unjustifiedAbsences, 1);
      expect(line.frozen, isTrue);
    });

    test('rouverte : les lignes figées disparaissent', () async {
      final dao = PayrollDao(db);
      await dao.apply(
        [
          _payroll('VALIDATED', lines: [_line('m-1')]),
        ],
        schoolId: _school,
        nowMs: 1,
      );

      await dao.apply([_payroll('DRAFT')], schoolId: _school, nowMs: 2);

      expect(await dao.frozenLines(_school), isEmpty);
    });

    test('un accusé sans lignes ne vide pas une paie validée', () async {
      final dao = PayrollDao(db);
      await dao.apply(
        [
          _payroll('VALIDATED', lines: [_line('m-1')]),
        ],
        schoolId: _school,
        nowMs: 1,
      );

      await dao.apply([_payroll('VALIDATED')], schoolId: _school, nowMs: 2);

      expect((await dao.frozenLines(_school))['2026-10'], hasLength(1));
    });

    test('un geste de la tablette descendu passe accusé', () async {
      final gestures = PayrollGestureDao(db);
      await gestures.add(
        const PayrollGestureRequestDto(
          gestureId: 'g-v',
          month: '2026-10',
          kind: 'VALIDATE',
          clientRecordedAt: '2026-10-26T10:00:00Z',
          authorId: 'u-1',
        ),
        schoolId: _school,
        nowMs: 1,
      );

      await PayrollDao(
        db,
      ).apply([_payroll('VALIDATED')], schoolId: _school, nowMs: 2);

      final gesture = (await gestures.forSchool(_school)).single;
      expect(gesture.syncState, RecordSyncState.synced);
      expect(gesture.authorName, 'Mbuyi Kalombo Jean-Pierre');
    });
  });

  group('dernier écrit gagne', () {
    test('des éléments variables en attente ne sont pas écrasés', () async {
      await PayrollVariablesDao(db).save(
        const PayrollVariablesRequestDto(
          month: '2026-10',
          staffMemberId: 'm-1',
          overtimeMinutes: 60,
          clientUpdatedAt: '2026-10-21T09:00:00Z',
          authorId: 'u-1',
        ),
        schoolId: _school,
        nowMs: 1,
      );

      await PayrollDao(
        db,
      ).apply([_payroll('DRAFT')], schoolId: _school, nowMs: 2);

      final variables = (await PayrollVariablesDao(
        db,
      ).forSchool(_school))['2026-10']!['m-1']!;
      expect(variables.overtimeMinutes, 60);
      expect(variables.syncState, RecordSyncState.pending);
      final entry = (await OutboxDao(db).pendingAll()).single;
      expect(entry.aggregateId, 'payroll:2026-10');
    });

    test('réglages : le socle ne les écrase pas tant qu ils partent', () async {
      final dao = PayrollSettingsDao(db);
      final seed = PayrollSettingsSeed.tryParse({
        'monthlyHoursDivisor': 195,
        'overtimeMultiplierPermille': 1500,
        'allowanceEligibleKinds': ['PERMANENT'],
        'currencyRules': [
          {
            'currency': 'usd',
            'childAllowanceInCents': 700,
            'defaultOvertimeRateInCents': 400,
            'overtimeRateStepInCents': 50,
          },
        ],
      })!;
      await dao.applySeed(seed, schoolId: _school, nowMs: 1);
      expect((await dao.read(_school)).monthlyHoursDivisor, 195);
      expect((await dao.read(_school)).of('USD').childAllowanceInCents, 700);

      await dao.save(
        PayrollSettingsRequestDto(
          settings: PayrollSettingsDao.toSeed(
            (await dao.read(_school)).copyWith(monthlyHoursDivisor: 173),
          ),
          clientUpdatedAt: '2026-10-02T08:00:00Z',
          authorId: 'u-1',
        ),
        schoolId: _school,
        nowMs: 2,
      );
      await dao.applySeed(seed, schoolId: _school, nowMs: 3);

      expect((await dao.read(_school)).monthlyHoursDivisor, 173);
    });

    test(
      'réglages v2 : relus entiers, défauts v1 quand le fil les tait',
      () async {
        final dao = PayrollSettingsDao(db);
        final v1 = PayrollSettingsSeed.tryParse({
          'monthlyHoursDivisor': 173,
          'overtimeMultiplierPermille': 1300,
          'allowanceEligibleKinds': <String>[],
          'currencyRules': [
            {
              'currency': 'USD',
              'childAllowanceInCents': 0,
              'defaultOvertimeRateInCents': 300,
              'overtimeRateStepInCents': 50,
            },
          ],
        })!;
        expect(v1.workDaysDivisor, 26);
        expect(v1.absenceDeductionEnabled, isFalse);
        expect(v1.byCurrency.single.iprFlatInCents, 0);

        final v2 = PayrollSettingsSeed.tryParse({
          ...v1.toJson(),
          'workDaysDivisor': 22,
          'absenceDeductionEnabled': true,
          'currencyRules': [
            {
              ...(v1.toJson()['currencyRules'] as List).single as Map,
              'iprFlatInCents': 200,
              'cnssPermille': 35,
            },
          ],
        })!;
        await dao.applySeed(v2, schoolId: _school, nowMs: 1);
        final read = await dao.read(_school);

        expect(read.workDaysDivisor, 22);
        expect(read.absenceDeductionEnabled, isTrue);
        expect(read.of('USD').iprFlatInCents, 200);
        expect(read.of('USD').cnssPermille, 35);
        expect(PayrollSettingsDao.toSeed(read).toJson(), v2.toJson());
      },
    );

    test('réglages v2 : un diviseur hors bornes retombe à 26', () {
      final seed = PayrollSettingsSeed.tryParse({
        'monthlyHoursDivisor': 173,
        'overtimeMultiplierPermille': 1300,
        'allowanceEligibleKinds': <String>[],
        'currencyRules': <Object>[],
        'workDaysDivisor': 40,
        'absenceDeductionEnabled': 'yes',
      })!;

      expect(seed.workDaysDivisor, 26);
      expect(seed.absenceDeductionEnabled, isFalse);
    });
  });

  test('résumés : un agent absent vaut zéro', () async {
    final dao = AttendanceSummaryDao(db);
    await dao.applyPulled(
      [
        AttendanceSummaryDto.tryParse({
          'month': '2026-08',
          'closedAt': '2026-08-31T15:00:00Z',
          'agents': [
            {'staffMemberId': 'm-2', 'workedMinutes': 2280, 'lates': 2},
          ],
        })!,
      ],
      schoolId: _school,
      nowMs: 1,
    );

    final summary = (await dao.forSchool(_school))['2026-08']!;
    expect(summary.of('m-2').workedMinutes, 2280);
    expect(summary.of('m-9').workedMinutes, 0);
    expect(jsonEncode(summary.agents.keys.toList()), '["m-2"]');
  });

  test(
    'un mois rouvert redescend sans clôture : son résumé s\'efface',
    () async {
      final dao = AttendanceSummaryDao(db);
      Future<void> pull(Map<String, Object?> raw) => dao.applyPulled(
        [AttendanceSummaryDto.tryParse(raw)!],
        schoolId: _school,
        nowMs: 1,
      );
      await pull({
        'month': '2026-10',
        'closedAt': '2026-10-31T15:00:00Z',
        'agents': [
          {'staffMemberId': 'm-2', 'unjustifiedAbsences': 2},
        ],
      });
      await pull({'month': '2026-10', 'closedAt': null, 'agents': []});

      expect(await dao.forSchool(_school), isEmpty);
    },
  );
}
