import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/presentation/export/payroll_payslip_pdf.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

void main() {
  testWidgets('le bulletin provisoire : même contenu à l écran et en PDF', (
    tester,
  ) async {
    final snapshot = PayrollSnapshot(
      members: [member('m-1')],
      contractsByMember: {
        'm-1': [contract('m-1')],
      },
      settings: PayrollSettings.defaults,
      profiles: const {},
      headers: const {},
      variables: const {},
      frozenLines: const {},
      summaries: const {},
      gestures: const [],
      advances: [advance('m-1', amount: 3000, installments: 3)],
      disbursements: const [],
      schoolYears: const [],
      shareTraces: const {},
      hasEverSynced: true,
    );
    final view = PayrollLedger.monthView(snapshot, '2026-10');
    late PayrollPayslipContent content;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            content = PayrollPayslipContent.of(
              context,
              snapshot: snapshot,
              view: view,
              line: view.lines.single,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(content.banner, 'Provisoire — non validée');
    expect(content.deductions.single.value, contains('10'));
    final bytes = await tester.runAsync(
      () => PayrollPayslipPdf.build([content]),
    );
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(4)), '%PDF');
  });
}
