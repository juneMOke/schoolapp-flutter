import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_schedule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../payroll_builders.dart';

/// Les vecteurs de la spec et du contrat serveur, en centimes. Le fichier de
/// vecteurs partagé du back (P1) viendra s'ajouter à ceux-ci.
void main() {
  PayrollEngineInput input({
    String month = '2026-10',
    required Map<String, List> contracts,
    Map<String, PayrollVariables> variables = const {},
    Map<String, StaffPayProfile> profiles = const {},
    AttendanceSummary? attendance,
    List advances = const [],
    List priorLines = const [],
    PayrollSettings settings = PayrollSettings.defaults,
  }) => PayrollEngineInput(
    month: month,
    settings: settings,
    contractsByMember: {
      for (final entry in contracts.entries) entry.key: entry.value.cast(),
    },
    variables: variables,
    profiles: profiles,
    attendance: attendance,
    advances: PayrollAdvanceSchedule.statesOf(
      advances.cast(),
      month,
      priorLines.cast(),
    ),
  );

  group('roundDiv', () {
    test('demi vers le haut, sur entiers', () {
      expect(PayrollMath.roundDiv(5, 2), 3);
      expect(PayrollMath.roundDiv(4, 2), 2);
      expect(PayrollMath.roundDiv(7, 3), 2);
      expect(PayrollMath.roundDiv(0, 60), 0);
    });
  });

  group(
    'la ligne de la spec (350 USD, 4 h sup., 3 enfants, avance 100 USD)',
    () {
      test(
        'taux 2,5 USD, heures sup. 10 USD, allocations 15 USD, net 275 USD',
        () {
          final result = PayrollEngine.compute(
            input(
              contracts: {
                'm-1': [contract('m-1')],
              },
              variables: {
                'm-1': const PayrollVariables(
                  staffMemberId: 'm-1',
                  overtimeMinutes: 240,
                ),
              },
              profiles: {
                'm-1': const StaffPayProfile(
                  staffMemberId: 'm-1',
                  dependentChildren: 3,
                ),
              },
              advances: [advance('m-1')],
            ),
          );

          final line = result.lines.single;
          expect(line.overtimeRateInCents, 250);
          expect(line.overtimeInCents, 1000);
          expect(line.allowanceInCents, 1500);
          expect(line.grossInCents, 37500);
          expect(line.advanceInCents, 10000);
          expect(line.netInCents, 27500);
        },
      );

      test('les enfants du mois priment sur ceux du profil', () {
        final line = PayrollEngine.compute(
          input(
            contracts: {
              'm-1': [contract('m-1')],
            },
            variables: {
              'm-1': const PayrollVariables(
                staffMemberId: 'm-1',
                dependentChildren: 1,
              ),
            },
            profiles: {
              'm-1': const StaffPayProfile(
                staffMemberId: 'm-1',
                dependentChildren: 3,
              ),
            },
          ),
        ).lines.single;

        expect(line.children, 1);
        expect(line.allowanceInCents, 500);
      });
    },
  );

  group('vacataire à l heure', () {
    test('38 h d août à 6 USD : 228 USD, et jamais d heures sup.', () {
      final line = PayrollEngine.compute(
        input(
          month: '2026-09',
          contracts: {
            'm-2': [
              contract(
                'm-2',
                kind: StaffContractKind.vacataire,
                payMode: StaffPayMode.hourly,
                amount: 600,
              ),
            ],
          },
          variables: {
            'm-2': const PayrollVariables(
              staffMemberId: 'm-2',
              overtimeMinutes: 120,
            ),
          },
          attendance: const AttendanceSummary(
            month: '2026-08',
            agents: {'m-2': AttendanceAgentSummary(workedMinutes: 2280)},
          ),
        ),
      ).lines.single;

      expect(line.baseInCents, 22800);
      expect(line.baseMinutes, 2280);
      expect(line.hoursMonth, '2026-08');
      expect(line.overtimeInCents, 0);
    });

    test('un mois hors année (pas de résumé) vaut zéro heure', () {
      final line = PayrollEngine.compute(
        input(
          month: '2026-09',
          contracts: {
            'm-2': [
              contract(
                'm-2',
                kind: StaffContractKind.vacataire,
                payMode: StaffPayMode.hourly,
                amount: 600,
              ),
            ],
          },
        ),
      ).lines.single;

      expect(line.baseInCents, 0);
      expect(line.netInCents, 0);
    });
  });

  group('contrat en francs', () {
    test('la ligne reste en CDF, taux au pas de 500 FC', () {
      final line = PayrollEngine.compute(
        input(
          contracts: {
            'm-3': [contract('m-3', amount: 50000000, currency: 'CDF')],
          },
          variables: {
            'm-3': const PayrollVariables(
              staffMemberId: 'm-3',
              overtimeMinutes: 60,
            ),
          },
          profiles: {
            'm-3': const StaffPayProfile(
              staffMemberId: 'm-3',
              dependentChildren: 1,
            ),
          },
        ),
      ).lines.single;

      expect(line.currency, 'CDF');
      expect(line.overtimeRateInCents, 400000);
      expect(line.allowanceInCents, 1400000);
      expect(line.grossInCents, 50000000 + 400000 + 1400000);
    });
  });

  group('conventionné', () {
    test('prime locale seule, taux d heure sup. par défaut', () {
      final line = PayrollEngine.compute(
        input(
          contracts: {
            'm-4': [
              contract(
                'm-4',
                kind: StaffContractKind.conventionne,
                amount: null,
                bonus: 5000,
              ),
            ],
          },
          variables: {
            'm-4': const PayrollVariables(
              staffMemberId: 'm-4',
              overtimeMinutes: 60,
            ),
          },
        ),
      ).lines.single;

      expect(line.baseInCents, 5000);
      expect(line.overtimeRateInCents, 300);
      expect(line.overtimeInCents, 300);
    });

    test('sans allocation quand son statut n y ouvre pas droit (A7)', () {
      final line = PayrollEngine.compute(
        input(
          settings: PayrollSettings.defaults.copyWith(
            allowanceEligibleKinds: {StaffContractKind.permanent},
          ),
          contracts: {
            'm-4': [
              contract(
                'm-4',
                kind: StaffContractKind.conventionne,
                amount: null,
                bonus: 5000,
              ),
            ],
          },
          profiles: {
            'm-4': const StaffPayProfile(
              staffMemberId: 'm-4',
              dependentChildren: 2,
            ),
          },
        ),
      ).lines.single;

      expect(line.allowanceInCents, 0);
    });
  });

  group('quel contrat paie (A2, E5)', () {
    test('celui en vigueur au dernier jour du mois', () {
      final line = PayrollEngine.compute(
        input(
          month: '2026-09',
          contracts: {
            'm-5': [
              contract('m-5', from: '2026-01-01', endsOn: '2026-09-14'),
              contract(
                'm-5',
                kind: StaffContractKind.vacataire,
                payMode: StaffPayMode.monthlyFlat,
                amount: 20000,
                from: '2026-09-15',
              ),
            ],
          },
        ),
      ).lines.single;

      expect(line.contractKind, StaffContractKind.vacataire);
      expect(line.contractFrom, '2026-09-15');
      expect(line.baseInCents, 20000);
    });

    test('un CDD fini le 15 sans successeur paie encore son mois', () {
      final result = PayrollEngine.compute(
        input(
          month: '2026-09',
          contracts: {
            'm-5': [contract('m-5', endsOn: '2026-09-15')],
          },
        ),
      );

      expect(result.lines.single.baseInCents, 35000);
    });

    test('une période corrigée ne paie pas ; sans contrat, hors livre', () {
      final result = PayrollEngine.compute(
        input(
          contracts: {
            'm-6': [contract('m-6', correctedAt: '2026-02-01T00:00:00Z')],
            'm-7': [],
            'm-8': [contract('m-8', endsOn: '2026-06-30')],
          },
        ),
      );

      expect(result.lines, isEmpty);
      expect(result.withoutContract, ['m-6', 'm-7']);
    });
  });

  test('une devise vide compte comme absente', () {
    final result = PayrollEngine.compute(
      input(
        contracts: {
          'm-1': [contract('m-1', currency: '')],
          'm-2': [
            contract(
              'm-2',
              kind: StaffContractKind.conventionne,
              amount: 1000000,
              currency: 'CDF',
              bonus: 10000,
            ),
          ],
        },
      ),
    );

    expect(result.lines.first.currency, 'USD');
    expect(result.lines.last.baseInCents, 10000);
  });
}
