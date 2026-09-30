import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_settings_dao.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_advance_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les vecteurs de référence du moteur de paie, **le même fichier que le
/// serveur** (`src/test/resources/payroll/engine-vectors.json`), copié tel
/// quel : un moteur qui diverge fait échouer la CI des deux dépôts. Ne jamais
/// le retoucher à la main — le recopier du dépôt serveur.
void main() {
  final vectors =
      jsonDecode(
            File(
              'test/fixtures/payroll/engine-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  for (final raw in vectors['cases'] as List) {
    final vector = raw as Map<String, dynamic>;
    test(vector['name'], () async {
      final month = vector['month'] as String;
      final input = _input(vector, vectors['defaultSettings'], month);
      final expected = vector['expected'] as Map<String, dynamic>;

      final result = PayrollEngine.compute(input);
      final fingerprint = await PayrollFingerprinter.of(result.lines);

      expect(result.withoutContract, expected['withoutContract']);
      expect(fingerprint.lineCount, expected['lineCount']);
      expect(fingerprint.linesDigest, expected['linesDigest']);
      expect([
        for (final total in fingerprint.totals)
          {
            'currency': total.currency,
            'grossInCents': total.grossInCents,
            'advanceInCents': total.advanceInCents,
            'netInCents': total.netInCents,
          },
      ], expected['totals']);
      final lines = expected['lines'] as List;
      expect(result.lines, hasLength(lines.length));
      for (final (index, rawLine) in lines.indexed) {
        final want = rawLine as Map<String, dynamic>;
        final line = result.lines[index];
        expect(
          {
            'staffMemberId': line.staffMemberId,
            'contractId': line.contractId,
            'currency': line.currency,
            'baseInCents': line.baseInCents,
            'baseMinutes': line.baseMinutes,
            'hoursMonth': line.hoursMonth,
            'overtimeMinutes': line.overtimeMinutes,
            'overtimeRateInCents': line.overtimeRateInCents,
            'overtimeInCents': line.overtimeInCents,
            'dependentChildren': line.children,
            'allowanceInCents': line.allowanceInCents,
            'grossInCents': line.grossInCents,
            'advances': [
              for (final a in line.advances)
                {
                  'advanceId': a.advanceId,
                  'rank': a.rank,
                  'due': a.dueInCents,
                  'taken': a.takenInCents,
                  'carried': a.carriedInCents,
                },
            ],
            'advanceInCents': line.advanceInCents,
            'netInCents': line.netInCents,
            'attendanceMonth': line.attendanceMonth,
          },
          want,
          reason: 'ligne $index',
        );
      }
    });
  }
}

PayrollEngineInput _input(
  Map<String, dynamic> vector,
  Object? defaultSettings,
  String month,
) {
  final staff = [
    for (final raw in vector['staff'] as List? ?? const [])
      raw as Map<String, dynamic>,
  ];
  return PayrollEngineInput(
    month: month,
    settings: PayrollSettingsDao.toEntity(
      _settings(vector['settings'] ?? defaultSettings),
    ),
    contractsByMember: {
      for (final agent in staff)
        agent['staffMemberId'] as String: [
          for (final c in agent['contracts'] as List)
            _contract(agent['staffMemberId'] as String, c as Map),
        ],
    },
    variables: {
      for (final agent in staff)
        if (agent['variables'] case final Map v)
          agent['staffMemberId'] as String: PayrollVariables(
            staffMemberId: agent['staffMemberId'] as String,
            overtimeMinutes: v['overtimeMinutes'] as int?,
            overtimeRateInCents: v['overtimeRateInCents'] as int?,
            dependentChildren: v['dependentChildren'] as int?,
          ),
    },
    profiles: {
      for (final agent in staff)
        if (agent['profileChildren'] case final int children)
          agent['staffMemberId'] as String: StaffPayProfile(
            staffMemberId: agent['staffMemberId'] as String,
            dependentChildren: children,
          ),
    },
    attendance: AttendanceSummary(
      month: PayrollMonth.previous(month),
      agents: {
        for (final agent in staff)
          if (agent['attendance'] case final Map a)
            agent['staffMemberId'] as String: AttendanceAgentSummary(
              workedMinutes: a['workedMinutes'] as int,
              unjustifiedAbsences: a['unjustifiedAbsences'] as int,
              justifiedAbsences: a['justifiedAbsences'] as int,
              lates: a['lates'] as int,
              lateMinutes: a['lateMinutes'] as int,
            ),
      },
    ),
    advances: {
      for (final agent in staff)
        agent['staffMemberId'] as String: [
          for (final a in agent['advances'] as List? ?? const [])
            PayrollAdvanceState(
              advanceId: (a as Map)['advanceId'] as String,
              amountInCents: a['amountInCents'] as int,
              currency: a['currency'] as String,
              installments: a['installments'] as int,
              firstMonth: a['firstMonth'] as String,
              maturedMonths: a['maturedMonths'] as int,
              alreadyTaken: a['alreadyTaken'] as int,
            ),
        ],
    },
  );
}

PayrollSettingsSeed _settings(Object? raw) =>
    PayrollSettingsSeed.tryParse(raw)!;

StaffContract _contract(String memberId, Map raw) {
  final amount = raw['amountInCents'] as int?;
  final bonus = raw['bonusInCents'] as int?;
  return StaffContract(
    id: raw['id'] as String,
    staffMemberId: memberId,
    kind: StaffContractKind.fromWire(raw['kind'] as String?),
    payMode: StaffPayMode.fromWire(raw['payMode'] as String?),
    effectiveFrom: raw['effectiveFrom'] as String,
    endsOn: raw['endsOn'] as String?,
    amount: amount == null
        ? null
        : Money.parse(amount, raw['currency'] as String),
    bonus: bonus == null
        ? null
        : Money.parse(bonus, raw['bonusCurrency'] as String),
    recordedAt: '2025-01-01T00:00:00Z',
    syncState: StaffSyncState.synced,
  );
}
