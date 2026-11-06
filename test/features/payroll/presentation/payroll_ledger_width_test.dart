import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_table.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

/// Le livre de paie sur un poste de 1 440 dp, barre latérale dépliée : il
/// reçoit 1 112 dp. À 1 124 dp de plancher, il défilait de 12 dp et l'œil
/// de fin de ligne (ouvrir la fiche) sortait du cadre.
void main() {
  PayrollSnapshot snapshot() => PayrollSnapshot(
    members: [
      member(
        'm-1',
        lastName: 'KABASELE-TSHIMANGA',
        firstName: 'Marie-Béatrice',
      ),
    ],
    contractsByMember: {
      'm-1': [contract('m-1')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: const {
      '2026-10': PayrollHeader(
        id: 'p',
        month: '2026-10',
        status: PayrollStatus.draft,
      ),
    },
    variables: const {},
    frozenLines: const {},
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: const [],
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  testWidgets('à 1 440 barre dépliée, le livre tient sans défiler', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    // Le harnais n'a pas de coquille : la fenêtre est la zone que la barre
    // latérale dépliée laisse à la page.
    tester.view.physicalSize = const Size(1440 - AppTheme.sidebarWidth, 1200);
    addTearDown(tester.view.reset);
    await pumpPayrollScreen(tester, snapshot: snapshot());
    await tester.pumpAndSettle();

    final table = find.byType(PayrollLedgerTable);
    expect(tester.getSize(table).width, 1112);
    final sideways = find
        .descendant(of: table, matching: find.byType(Scrollable))
        .evaluate()
        .map((e) => ((e as StatefulElement).state as ScrollableState).position)
        .where((p) => p.axis == Axis.horizontal);
    for (final position in sideways) {
      expect(position.maxScrollExtent, 0);
    }
    // La colonne d'ouverture entière dans le cadre du livre.
    final eye = find.byTooltip("Ouvrir la fiche de l'agent");
    final button = find.ancestor(of: eye, matching: find.byType(IconButton));
    expect(
      tester.getRect(button).right,
      lessThanOrEqualTo(tester.getRect(table).right),
    );
  });
}
