import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_payout_policy_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_line_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

/// La Paie v2 dans la base : variables v2, taux du mois, lignes figées v2.
const _school = 's-1';

PayrollDto _draft({Map<String, dynamic>? policy, List? variables}) =>
    PayrollDto.tryParse({
      'id': 'p-10',
      'month': '2026-10',
      'status': 'DRAFT',
      'variables': ?variables,
      'payoutPolicy': ?policy,
    })!;

void main() {
  late Database db;

  setUp(() async => db = await openFullOfflineDb());
  tearDown(() => db.close());

  test(
    'variables v2 : NJP, PC/E et montant fixe descendent et se relisent',
    () async {
      await PayrollDao(db).apply(
        [
          _draft(
            variables: [
              {
                'staffMemberId': 'm-1',
                'workedDays': 20,
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
      expect(v.workedDays, 20);
      expect(v.childcareInCents, 1500);
      expect(v.fixedPayoutInCents, 10000);
      expect(v.fixedPayoutReason, 'Trésorerie');
    },
  );

  test('variables v2 : la requête figée se relit à l identique', () {
    const sent = PayrollVariablesRequestDto(
      month: '2026-10',
      staffMemberId: 'm-1',
      workedDays: 22,
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

  group('taux du mois', () {
    test('descend avec la paie', () async {
      await PayrollDao(db).apply(
        [
          _draft(
            policy: {
              'ratePercent': 60,
              'reason': 'Trésorerie tendue',
              'clientUpdatedAt': '2026-10-20T09:00:00Z',
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
                'ratePercent': 100,
                'clientUpdatedAt': '2026-10-20T09:00:00Z',
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
      'un serveur qui n en porte pas n efface rien ; hors bornes = ignoré',
      () async {
        await PayrollDao(db).apply(
          [
            _draft(
              policy: {
                'ratePercent': 75,
                'clientUpdatedAt': '2026-10-20T09:00:00Z',
              },
            ),
          ],
          schoolId: _school,
          nowMs: 1,
        );
        await PayrollDao(db).apply([_draft()], schoolId: _school, nowMs: 2);
        await PayrollDao(db).apply(
          [
            _draft(
              policy: {
                'ratePercent': 140,
                'clientUpdatedAt': '2026-10-22T09:00:00Z',
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
              'workedDays': 13,
              'absenceInCents': 15000,
              'iprInCents': 200,
            },
            'payout': {'toPayInCents': 8880, 'ratePercent': 60},
          },
        ),
        month: '2026-10',
      )!;

      expect(parsed.formulaVersion, 2);
      expect(parsed.deductions.absentDays, 13);
      expect(parsed.deductions.totalInCents, 15200);
      expect(parsed.toPayInCents, 8880);
      expect(parsed.deferredInCents, 5920);
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
}
