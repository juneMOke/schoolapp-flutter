import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_payout_policy.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_advances_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_agent_page.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

/// Le livre v2 et la fiche d'un agent aux formats de référence (AGENTS.md §« Écran
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

  testAtReferenceFormats('Livre de paie v2', (tester, format) async {
    await pumpPayrollScreen(tester, snapshot: snapshot);

    expect(find.text('Modifier le taux'), findsOneWidget);
  });

  testAtReferenceFormats('Fiche de l agent v2', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: const PayrollAgentScreen(agentId: 'm-1', entryMonth: '2026-10'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salaire brut (A)'), findsOneWidget);
  });

  testAtReferenceFormats('Avances & prêts', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: const PayrollAdvancesScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Mayala'), findsWidgets);
  });
}
