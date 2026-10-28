import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_agent_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tranche_list.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_sheet.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

/// La fiche d'un agent : sa situation de paie sur un écran — ce que l'école
/// lui doit, ses mois, son rang dans le livre — à tous les formats.
void main() {
  PayrollSnapshot snapshotOf({List<PayrollDisbursement> paid = const []}) =>
      PayrollSnapshot(
        members: [
          member(
            'm-1',
            lastName: 'KABASELE-TSHIMANGA',
            firstName: 'Marie-Béatrice',
          ),
          member('m-2', lastName: 'Mayala', firstName: 'Ruth'),
        ],
        contractsByMember: {
          'm-1': [contract('m-1', from: '2026-01-01')],
          'm-2': [contract('m-2', from: '2026-01-01', amount: 22800)],
        },
        settings: PayrollSettings.defaults,
        profiles: const {},
        headers: const {
          '2026-09': PayrollHeader(
            id: 'p-09',
            month: '2026-09',
            status: PayrollStatus.validated,
            validationGestureId: 'g-09',
          ),
        },
        variables: const {},
        frozenLines: {
          '2026-09': [
            frozenLine('m-1', '2026-09'),
            frozenLine('m-2', '2026-09', gross: 22800),
          ],
        },
        summaries: const {},
        gestures: const [],
        advances: [advance('m-1', amount: 30000, installments: 3)],
        disbursements: paid,
        schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
        shareTraces: const {},
        hasEverSynced: true,
      );

  PayrollDisbursement paid(int cents) => PayrollDisbursement(
    id: 'd-1',
    month: '2026-09',
    staffMemberId: 'm-1',
    validationGestureId: 'g-09',
    amount: Money(cents, 'USD'),
    mode: PayoutMode.cash,
    paidAt: '2026-09-28T09:00:00.000Z',
    signedRegister: true,
  );

  Future<void> pumpAgent(
    WidgetTester tester, {
    required PayrollSnapshot snapshot,
    String agentId = 'm-1',
  }) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: PayrollAgentScreen(agentId: agentId, entryMonth: '2026-10'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le bandeau : l agent, son rang au livre, le reste dû', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAgent(tester, snapshot: snapshotOf(paid: [paid(10000)]));

    expect(find.textContaining('KABASELE-TSHIMANGA'), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Reste dû par l\'école'), findsOneWidget);
    expect(find.text('1 mois non soldé'), findsOneWidget);
    expect(find.text('Perçu en 2026'), findsOneWidget);
    expect(find.text('Fiches de paie · 2 mois'), findsOneWidget);
    expect(find.text('Partiel'), findsOneWidget);
  });

  testWidgets('toucher un mois l affiche à côté', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshotOf(),
      child: const PayrollAgentScreen(agentId: 'm-1', entryMonth: '2026-10'),
    );
    await tester.pumpAndSettle();
    expect(pumped.cubit.state.month, '2026-10');

    await tester.tap(find.text('Septembre 2026').first);
    await tester.pumpAndSettle();

    expect(pumped.cubit.state.month, '2026-09');
  });

  testWidgets('le détail du calcul, puis le bulletin du même mois', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAgent(tester, snapshot: snapshotOf());

    expect(find.text('GAINS'), findsOneWidget);
    expect(find.text('Salaire brut (A)'), findsOneWidget);
    expect(find.text('Total retenues (B)'), findsOneWidget);
    expect(find.text('Éléments variables'), findsOneWidget);
    expect(
      find.text('Les versements seront possibles après validation.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Bulletin'));
    await tester.pumpAndSettle();

    expect(find.byType(PayrollPayslipSheet), findsOneWidget);
    expect(find.text('GAINS'), findsNothing);
    expect(
      find.text('Rémunération due (net à payer) · (A) − (B)'),
      findsOneWidget,
    );
    expect(find.text('RESTE À PERCEVOIR'), findsOneWidget);
  });

  testWidgets('un mois validé non soldé : verser le reste, ses versements', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAgent(tester, snapshot: snapshotOf(paid: [paid(10000)]));
    await tester.tap(find.text('Septembre 2026').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Verser · reste'), findsOneWidget);
    expect(find.text('Éléments variables'), findsNothing);
    expect(find.byType(PayrollTrancheList), findsOneWidget);
  });

  testWidgets('la direction consulte les versements, sans verser', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPayrollScreen(
      tester,
      snapshot: snapshotOf(paid: [paid(10000)]),
      permissions: const [Perm.hrPayRead, Perm.hrPayManage],
      child: const PayrollAgentScreen(agentId: 'm-1', entryMonth: '2026-10'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Septembre 2026').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Verser · reste'), findsNothing);
    expect(find.text('Versements'), findsOneWidget);
  });

  testWidgets('la colonne gauche : prêt, arriéré du mois, cumuls de l année', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAgent(tester, snapshot: snapshotOf(paid: [paid(10000)]));

    expect(find.text('Prêts & avances'), findsOneWidget);
    expect(find.text('Prêt · 3 mois'), findsOneWidget);
    expect(find.textContaining('Prochaine retenue'), findsOneWidget);
    expect(find.text('Arriérés de salaire'), findsOneWidget);
    expect(find.text('Régler les arriérés'), findsOneWidget);
    expect(find.text('Cumuls · 2026'), findsOneWidget);
    expect(find.text('Sur 1 mois validé.'), findsOneWidget);
  });

  testWidgets('un livre sans paie au serveur : la fiche s ouvre sur ce mois', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshotOf(),
      child: const PayrollAgentScreen(agentId: 'm-1', entryMonth: '2026-08'),
      beforeLoad: (cubit) => cubit.showMonth('2026-08'),
    );
    await tester.pumpAndSettle();

    expect(pumped.cubit.state.month, '2026-08');
    expect(find.text('Août 2026'), findsWidgets);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('un agent sans paie : la fiche le dit et ramène au livre', (
    tester,
  ) async {
    await pumpAgent(tester, snapshot: snapshotOf(), agentId: 'm-404');

    expect(find.text('Aucune fiche de paie'), findsOneWidget);
    expect(find.widgetWithText(EteeloButton, 'Livre de paie'), findsOneWidget);
  });

  testWidgets('livre en brouillon : le crayon ouvre les éléments variables', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPayrollScreen(tester, snapshot: snapshotOf());
    await tester.pumpAndSettle();

    final pencils = find.byTooltip('Éléments variables');
    expect(pencils, findsNWidgets(2));
    await tester.tap(pencils.first);
    await tester.pumpAndSettle();

    expect(find.text('Éléments variables'), findsWidgets);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testAtReferenceFormats('Fiche de l agent', (tester, format) async {
    await pumpAgent(tester, snapshot: snapshotOf(paid: [paid(10000)]));

    expect(find.text('Reste dû par l\'école'), findsOneWidget);
  });
}
