import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../payroll_builders.dart';

const _withDefault = PayrollDeductionType(
  id: 'a',
  label: 'Cartes',
  currency: 'USD',
  defaultAmountInCents: 1000,
  sortOrder: 10,
);
const _idle = PayrollDeductionType(
  id: 'b',
  label: 'Tenue',
  currency: 'USD',
  sortOrder: 20,
);

PayrollLine _line() => PayrollEngine.compute(
  PayrollEngineInput(
    month: '2026-10',
    settings: PayrollSettings.defaults,
    contractsByMember: {
      'm-1': [contract('m-1')],
    },
    deductionTypes: const [_withDefault, _idle],
  ),
).lines.single;

void main() {
  Future<List<PayslipRow>> rows(
    WidgetTester tester, {
    List<PayrollDeductionType> idle = const [],
    PayrollSettings settings = PayrollSettings.defaults,
  }) async {
    late List<PayslipRow> result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            result = PayrollPayslipRows.deductions(
              context,
              _line(),
              const {},
              settings: settings,
              idle: idle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('le détail liste une rubrique à 0, avant le total', (
    tester,
  ) async {
    final all = await rows(tester, idle: const [_idle]);

    final tenue = all.firstWhere((row) => row.label == 'Tenue');
    expect(tenue.value, PayrollPayslipRows.none);
    expect(all.indexOf(tenue), all.length - 2);
  });

  testWidgets('une retenue coupée sans montant ne se liste plus', (
    tester,
  ) async {
    final all = await rows(
      tester,
      settings: PayrollSettings.defaults.copyWith(
        legalDeductionsEnabled: false,
        salaryAdvancesEnabled: false,
        staffLoansEnabled: false,
        childcareEnabled: false,
      ),
    );

    final labels = all.map((row) => row.label);
    expect(labels, isNot(contains('Remboursement prêt')));
    expect(labels, isNot(contains('Avance sur salaire')));
    expect(labels, isNot(contains('Prise en charge enfant du personnel')));
    expect(labels, isNot(contains('Absence non justifiée')));
  });

  testWidgets('un montant venu du défaut le dit', (tester) async {
    final all = await rows(tester);

    expect(
      all.firstWhere((row) => row.label == 'Cartes').note,
      'Montant par défaut',
    );
    expect(all.any((row) => row.label == 'Tenue'), isFalse);
  });
}
