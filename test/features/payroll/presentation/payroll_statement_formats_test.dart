import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_payout_policy.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

/// L'état de paie et le livre v2 aux formats de référence (AGENTS.md §« Écran
/// neuf ») : deux catégories, deux devises, retenues et versement réduit,
/// des noms longs — sans débordement.
void main() {
  final usd = PayrollSettings.defaults.of('USD');
  final snapshot = PayrollSnapshot(
    members: [
      member(
        'm-1',
        lastName: 'KABASELE-TSHIMANGA',
        firstName: 'Marie-Béatrice',
      ),
      member('m-2', lastName: 'Mayala', firstName: 'Ruth'),
      member('m-3', lastName: 'Kalala', firstName: 'Didier'),
    ],
    contractsByMember: {
      'm-1': [contract('m-1', amount: 30000)],
      'm-2': [contract('m-2', amount: 22800)],
      'm-3': [contract('m-3', amount: 185000000, currency: 'CDF')],
    },
    settings: PayrollSettings.defaults.copyWith(
      absenceDeductionEnabled: true,
      byCurrency: {
        ...PayrollSettings.defaults.byCurrency,
        'USD': PayrollCurrencySettings(
          childAllowanceInCents: usd.childAllowanceInCents,
          defaultOvertimeRateInCents: usd.defaultOvertimeRateInCents,
          overtimeRateStepInCents: usd.overtimeRateStepInCents,
          iprFlatInCents: 200,
          cnssPermille: 35,
        ),
      },
    ),
    profiles: const {},
    headers: const {},
    variables: const {},
    frozenLines: const {},
    summaries: const {},
    gestures: const [],
    advances: [advance('m-2', amount: 4000)],
    disbursements: const [],
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
    payoutPolicies: const {
      '2026-10': PayrollPayoutPolicy(
        month: '2026-10',
        ratePercent: 60,
        reason: 'Trésorerie tendue après la rentrée',
      ),
    },
  );

  testAtReferenceFormats('État de paie v2', (tester, format) async {
    final cubit = await pumpPayrollScreen(tester, snapshot: snapshot);
    cubit.setTab(PayrollTab.statement);
    await tester.pumpAndSettle();

    expect(find.text('Total général · USD'), findsOneWidget);
    expect(find.textContaining('Brut'), findsWidgets);
  });

  testAtReferenceFormats('Livre de paie v2', (tester, format) async {
    await pumpPayrollScreen(tester, snapshot: snapshot);

    expect(find.text('Modifier le taux'), findsOneWidget);
  });
}
