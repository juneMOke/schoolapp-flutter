import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_arrears_priority_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_payout_policy_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_arrears_priority_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_line_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// La Paie v2 dans la base : variables v2, taux du mois, lignes figées v2.
const _school = 's-1';

/// Le taux du mois descend à plat sur la paie (`payoutPercent`…).
PayrollDto _draft({Map<String, dynamic>? policy, List? variables}) =>
    PayrollDto.tryParse({
      'id': 'p-10',
      'month': '2026-10',
      'status': 'DRAFT',
      'variables': ?variables,
      ...?policy,
    })!;

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  test('variables : PC/E et montant fixe descendent et se relisent, plus les '
      'jours prestés', () async {
    await PayrollDao(db).apply(
      [
        _draft(
          variables: [
            {
              'staffMemberId': 'm-1',
              'daysWorked': 20,
              'childcareInCents': 1500,
              'fixedPayoutInCents': 10000,
              'fixedPayoutReason': 'Trésorerie',
              'clientUpdatedAt': '2026-10-20T09:00:00Z',
            },
          ],
        ),
      ],
      schoolId: _school,
      nowMs: 1,
    );

    final v = (await PayrollVariablesDao(
      db,
    ).forSchool(_school))['2026-10']!['m-1']!;
    expect(v.childcareInCents, 1500);
    expect(v.fixedPayoutInCents, 10000);
    expect(v.fixedPayoutReason, 'Trésorerie');
  });

  test('variables v2 : la requête figée se relit à l identique', () {
    const sent = PayrollVariablesRequestDto(
      month: '2026-10',
      staffMemberId: 'm-1',
      childcareInCents: 500,
      fixedPayoutInCents: 9000,
      fixedPayoutReason: 'Accord',
      clientUpdatedAt: '2026-10-21T09:00:00.000Z',
      authorId: 'u-1',
    );

    expect(
      PayrollVariablesRequestDto.tryParse(sent.toJson())!.toJson(),
      sent.toJson(),
    );
  });

  test('le fil : plus de daysWorked, formulaVersion 3, payout.percent', () {
    const variables = PayrollVariablesRequestDto(
      month: '2026-10',
      staffMemberId: 'm-1',
      clientUpdatedAt: '2026-10-21T09:00:00.000Z',
      authorId: 'u-1',
    );
    const payout = PayrollPayoutPolicyRequestDto(
      month: '2026-10',
      ratePercent: 60,
      reason: 'Trésorerie',
      clientUpdatedAt: '2026-10-21T09:00:00.000Z',
      authorId: 'u-1',
    );

    final sent = variables.toJson()['variables'] as Map;
    expect(sent.containsKey('daysWorked'), isFalse);
    expect(sent['formulaVersion'], 3);
    expect(sent.containsKey('workedDays'), isFalse);
    expect(payout.toJson()['payout'], {
      'month': '2026-10',
      'percent': 60,
      'reason': 'Trésorerie',
      'clientUpdatedAt': '2026-10-21T09:00:00.000Z',
    });
  });

  group('taux du mois', () {
    test('descend avec la paie', () async {
      await PayrollDao(db).apply(
        [
          _draft(
            policy: {
              'payoutPercent': 60,
              'payoutReason': 'Trésorerie tendue',
              'payoutClientUpdatedAt': '2026-10-20T09:00:00Z',
            },
          ),
        ],
        schoolId: _school,
        nowMs: 1,
      );

      final policy = (await PayrollPayoutPolicyDao(
        db,
      ).forSchool(_school))['2026-10']!;
      expect(policy.ratePercent, 60);
      expect(policy.reason, 'Trésorerie tendue');
      expect(policy.syncState, RecordSyncState.synced);
    });

    test(
      'une saisie en attente n est pas écrasée, et part sous le mois',
      () async {
        final dao = PayrollPayoutPolicyDao(db);
        await dao.save(
          const PayrollPayoutPolicyRequestDto(
            month: '2026-10',
            ratePercent: 50,
            reason: 'Accord du conseil',
            clientUpdatedAt: '2026-10-21T09:00:00Z',
            authorId: 'u-1',
          ),
          schoolId: _school,
          nowMs: 1,
        );

        await PayrollDao(db).apply(
          [
            _draft(
              policy: {
                'payoutPercent': 100,
                'payoutClientUpdatedAt': '2026-10-20T09:00:00Z',
              },
            ),
          ],
          schoolId: _school,
          nowMs: 2,
        );

        final policy = (await dao.forSchool(_school))['2026-10']!;
        expect(policy.ratePercent, 50);
        expect(policy.syncState, RecordSyncState.pending);
        final entry = (await OutboxDao(db).pendingAll()).single;
        expect(entry.aggregateId, 'payroll:2026-10');
      },
    );

    test(
      'le 100 % jamais réglé n efface rien ; hors bornes = ignoré',
      () async {
        await PayrollDao(db).apply(
          [
            _draft(
              policy: {
                'payoutPercent': 75,
                'payoutReason': 'Caisse',
                'payoutClientUpdatedAt': '2026-10-20T09:00:00Z',
              },
            ),
          ],
          schoolId: _school,
          nowMs: 1,
        );
        await PayrollDao(db).apply(
          [
            _draft(policy: {'payoutPercent': 100}),
          ],
          schoolId: _school,
          nowMs: 2,
        );
        await PayrollDao(db).apply(
          [
            _draft(
              policy: {
                'payoutPercent': 140,
                'payoutClientUpdatedAt': '2026-10-22T09:00:00Z',
              },
            ),
          ],
          schoolId: _school,
          nowMs: 3,
        );

        expect(
          (await PayrollPayoutPolicyDao(
            db,
          ).forSchool(_school))['2026-10']!.ratePercent,
          75,
        );
      },
    );
  });

  group('lignes figées', () {
    Map<String, dynamic> line({Map<String, dynamic>? extra}) => {
      'staffMemberId': 'm-1',
      'currency': 'USD',
      'base': {'amountInCents': 30000},
      'grossInCents': 30000,
      'netInCents': 14800,
      ...?extra,
    };

    test('v2 : version, retenues et versement relus', () {
      final parsed = PayrollLineJson.tryParse(
        line(
          extra: {
            'formulaVersion': 2,
            'deductions': {
              'workDaysDivisor': 26,
              'daysWorked': 13,
              'absenceInCents': 15000,
              'iprInCents': 200,
            },
            'payout': {
              'toPayInCents': 8880,
              'deferredInCents': 5920,
              'percent': 60,
              'reason': 'Trésorerie',
            },
          },
        ),
        month: '2026-10',
      )!;

      expect(parsed.formulaVersion, 2);
      expect(parsed.deductions.absentDays, 13);
      expect(parsed.deductions.totalInCents, 15200);
      expect(parsed.toPayInCents, 8880);
      expect(parsed.deferredInCents, 5920);
      expect(parsed.payout?.ratePercent, 60);
      expect(parsed.payout?.reason, 'Trésorerie');
      expect(parsed.payout?.fixed, isFalse);
    });

    test('v2 : un montant fixe se lit à son montant', () {
      final parsed = PayrollLineJson.tryParse(
        line(
          extra: {
            'formulaVersion': 2,
            'payout': {
              'toPayInCents': 14800,
              'deferredInCents': 0,
              'percent': null,
              'fixedInCents': 20000,
              'reason': 'Accord',
            },
          },
        ),
        month: '2026-10',
      )!;

      expect(parsed.payout?.fixed, isTrue);
      expect(parsed.payout?.fixedInCents, 20000);
      expect(parsed.toPayInCents, 14800);
    });

    test(
      'v1 : tout le net à verser ; un « à verser » au-delà du net est ignoré',
      () {
        final v1 = PayrollLineJson.tryParse(line(), month: '2026-10')!;
        final absurd = PayrollLineJson.tryParse(
          line(
            extra: {
              'payout': {'toPayInCents': 99999},
            },
          ),
          month: '2026-10',
        )!;

        expect(v1.formulaVersion, 1);
        expect(v1.toPayInCents, 14800);
        expect(absurd.toPayInCents, 14800);
      },
    );
  });

  group('priorité des arriérés', () {
    PayrollArrearsPriorityDto flag(bool on, String at) =>
        PayrollArrearsPriorityDto(
          id: 'p-1',
          staffMemberId: 'm-1',
          month: '2026-09',
          prioritized: on,
          clientUpdatedAt: at,
        );

    test('descend, puis une saisie en attente n est pas écrasée', () async {
      final dao = PayrollArrearsPriorityDao(db);
      await dao.applyPulled(
        [flag(true, '2026-10-01T09:00:00Z')],
        schoolId: _school,
        nowMs: 1,
      );
      expect(await dao.prioritized(_school), {'2026-09|m-1'});

      await dao.save(
        PayrollArrearsPriorityRequestDto(
          priority: flag(false, '2026-10-02T09:00:00Z'),
          authorId: 'u-1',
        ),
        schoolId: _school,
        nowMs: 2,
      );
      await dao.applyPulled(
        [flag(true, '2026-10-01T09:00:00Z')],
        schoolId: _school,
        nowMs: 3,
      );

      expect(await dao.prioritized(_school), isEmpty);
      final entry = (await OutboxDao(db).pendingAll()).single;
      expect(entry.aggregateId, 'payroll-line:2026-09:m-1');
    });

    test('la requête figée se relit à l identique', () {
      final sent = PayrollArrearsPriorityRequestDto(
        priority: flag(true, '2026-10-02T09:00:00.000Z'),
        authorId: 'u-1',
      );

      expect(
        PayrollArrearsPriorityRequestDto.tryParse(sent.toJson())!.toJson(),
        sent.toJson(),
      );
    });
  });
}
