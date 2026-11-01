import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_dialog.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_rows.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'payroll_screen_harness.dart';

class _MockDeductions extends Mock implements PayrollDeductionRepository {}

const _month = '2026-10';
const _cards = PayrollDeductionType(id: 'a', label: 'Cartes', sortOrder: 10);
const _old = PayrollDeductionType(
  id: 'z',
  label: 'Ancienne',
  sortOrder: 90,
  archived: true,
);

PayrollDeductionEntry _entry({
  String type = 'a',
  int amount = 500,
  String currency = 'USD',
  RecordSyncState state = RecordSyncState.synced,
  String? code,
}) => PayrollDeductionEntry(
  staffMemberId: 'm-1',
  deductionTypeId: type,
  amountInCents: amount,
  currency: currency,
  syncState: state,
  syncErrorCode: code,
);

PayrollSnapshot _snapshot(
  List<PayrollDeductionEntry> entries, {
  PayrollStatus status = PayrollStatus.draft,
}) => PayrollSnapshot(
  members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
  contractsByMember: {
    'm-1': [contract('m-1')],
  },
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: {_month: PayrollHeader(id: 'p', month: _month, status: status)},
  variables: const {},
  deductionTypes: const [_cards, _old],
  deductions: {
    _month: {'m-1': entries},
  },
  frozenLines: const {},
  summaries: const {},
  gestures: const [],
  advances: const [],
  disbursements: const [],
  schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
  shareTraces: const {},
  hasEverSynced: true,
);

void main() {
  const manager = [Perm.hrPayRead, Perm.hrPayManage];
  late _MockDeductions deductions;

  setUpAll(() {
    registerFallbackValue(_entry());
  });

  setUp(() {
    deductions = _MockDeductions();
    when(
      () => deductions.dismissEntry(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  Future<void> wide(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  group('les annonces du livre', () {
    testWidgets('autre devise en brouillon : nomme l\'agent et la rubrique', (
      tester,
    ) async {
      await wide(tester);
      await pumpPayrollScreen(
        tester,
        snapshot: _snapshot([_entry(currency: 'CDF')]),
      );

      expect(find.textContaining('Ressaisissez le montant'), findsOneWidget);
      expect(find.textContaining('(Cartes)'), findsOneWidget);
    });

    testWidgets('autre devise sur paie soumise : renvoyer d\'abord', (
      tester,
    ) async {
      await wide(tester);
      await pumpPayrollScreen(
        tester,
        permissions: manager,
        snapshot: _snapshot([
          _entry(currency: 'CDF'),
        ], status: PayrollStatus.submitted),
      );

      expect(
        find.textContaining('La direction renvoie d\'abord la paie'),
        findsOneWidget,
      );
    });

    testWidgets('un refus se lit, et « J\'ai lu » l\'efface', (tester) async {
      await wide(tester);
      await pumpPayrollScreen(
        tester,
        deductions: deductions,
        snapshot: _snapshot([
          _entry(
            state: RecordSyncState.failed,
            code: PayrollDeductionCodes.tombstoned,
          ),
        ]),
      );

      expect(
        find.textContaining('Retenues retirées du calcul'),
        findsOneWidget,
      );

      await tester.tap(find.text("J'ai lu"));
      await tester.pump();

      verify(() => deductions.dismissEntry(_month, any())).called(1);
    });

    testWidgets('la direction sans écriture lit le refus, sans l\'effacer', (
      tester,
    ) async {
      await wide(tester);
      await pumpPayrollScreen(
        tester,
        permissions: manager,
        snapshot: _snapshot([
          _entry(state: RecordSyncState.failed),
        ], status: PayrollStatus.submitted),
      );

      expect(
        find.textContaining('Retenues retirées du calcul'),
        findsOneWidget,
      );
      expect(find.text("J'ai lu"), findsNothing);
    });
  });

  group('la modale jusqu\'à l\'enregistrement', () {
    Future<ValueNotifier<PayrollVariablesResult?>> open(
      WidgetTester tester, {
      required List<PayrollDeductionType> types,
      required List<PayrollDeductionEntry> entries,
    }) async {
      await wide(tester);
      final result = ValueNotifier<PayrollVariablesResult?>(null);
      const line = PayrollLine(
        month: _month,
        staffMemberId: 'm-1',
        currency: 'USD',
        baseInCents: 35000,
        grossInCents: 35000,
        netInCents: 35000,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result.value = await PayrollVariablesDialog.show(
                    context,
                    PayrollVariablesDialog(
                      name: 'Ruth',
                      line: line,
                      current: const PayrollVariables(staffMemberId: 'm-1'),
                      settings: PayrollSettings.defaults,
                      deductionTypes: types,
                      entries: entries,
                      preview: (_, _) => line,
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return result;
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
    }

    testWidgets('sans geste, un montant refusé ne repart pas', (tester) async {
      final result = await open(
        tester,
        types: const [_cards],
        entries: [_entry(state: RecordSyncState.failed)],
      );

      await save(tester);

      expect(result.value!.entries, isEmpty);
    });

    testWidgets('une archivée mise à 0 part à 0', (tester) async {
      final result = await open(
        tester,
        types: const [_old],
        entries: [_entry(type: 'z')],
      );

      await tester.ensureVisible(find.text('Mettre à 0'));
      await tester.pump();
      await tester.tap(find.text('Mettre à 0'));
      await tester.pump();
      await save(tester);

      expect(result.value!.entries.single.amountInCents, 0);
    });

    testWidgets('archivée en autre devise : montré, et effaçable', (
      tester,
    ) async {
      final result = await open(
        tester,
        types: const [_old],
        entries: [_entry(type: 'z', currency: 'CDF')],
      );

      expect(find.textContaining('FC'), findsWidgets);
      await tester.ensureVisible(find.text('Mettre à 0'));
      await tester.pump();
      await tester.tap(find.text('Mettre à 0'));
      await tester.pump();
      await save(tester);

      expect(result.value!.entries.single.amountInCents, 0);
    });

    testWidgets('un montant illisible se dit, et bloque', (tester) async {
      final result = await open(
        tester,
        types: const [_cards],
        entries: const [],
      );

      await tester.enterText(find.byType(TextField).last, '12a');
      await tester.pump();

      expect(find.text('Montant invalide.'), findsOneWidget);
      await save(tester);
      expect(result.value, isNull);
    });
  });

  testWidgets('le bulletin liste les rubriques après le modèle, rognage dit', (
    tester,
  ) async {
    late List<dynamic> rows;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            rows = PayrollPayslipRows.deductions(
              settings: PayrollSettings.defaults,
              context,
              const PayrollLine(
                month: _month,
                staffMemberId: 'm-1',
                currency: 'USD',
                baseInCents: 300,
                grossInCents: 300,
                netInCents: 0,
                deductions: PayrollLineDeductions(
                  custom: [
                    PayrollLineCustomDeduction(
                      deductionTypeId: 'a',
                      label: 'Cartes',
                      requestedInCents: 500,
                      takenInCents: 300,
                    ),
                  ],
                ),
              ),
              const {},
            );
            return const SizedBox();
          },
        ),
      ),
    );

    final custom = rows[rows.length - 2];
    expect(custom.label, 'Cartes');
    expect(custom.note, contains('Saisi'));
    expect(rows.last.value, contains('3'));
  });
}
