import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_deduction_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_custom.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_variables_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

class _MockRepository extends Mock implements PayrollDeductionRepository {}

const _month = '2026-10';
const _cards = PayrollDeductionType(id: 'a', label: 'Cartes', sortOrder: 10);
const _old = PayrollDeductionType(
  id: 'z',
  label: 'Ancienne',
  sortOrder: 90,
  archived: true,
);

PayrollDeductionEntry _entry(
  String type,
  int amount, {
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

PayrollSnapshot _snapshot(List<PayrollDeductionEntry> entries) =>
    PayrollSnapshot(
      members: [member('m-1')],
      contractsByMember: {
        'm-1': [contract('m-1')],
      },
      settings: PayrollSettings.defaults,
      profiles: const {},
      headers: const {},
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
      schoolYears: const [],
      shareTraces: const {},
      hasEverSynced: true,
    );

const _line = PayrollLine(
  month: _month,
  staffMemberId: 'm-1',
  currency: 'USD',
  baseInCents: 35000,
  grossInCents: 35000,
  netInCents: 35000,
);

const _draft = PayrollMonthView(
  month: _month,
  header: null,
  phase: PayrollPhase.draft,
  lines: [_line],
  totals: [],
  disbursements: {},
  withoutContract: [],
  zeroHourMembers: [],
  attendance: PayrollAttendanceState.closed,
);

const _submitted = PayrollMonthView(
  month: _month,
  header: null,
  phase: PayrollPhase.submitted,
  lines: [_line],
  totals: [],
  disbursements: {},
  withoutContract: [],
  zeroHourMembers: [],
  attendance: PayrollAttendanceState.closed,
);

void main() {
  group('aperçu', () {
    PayrollLine? preview(
      List<PayrollDeductionEntry> stored, {
      List<PayrollDeductionEntry>? entries,
    }) => PayrollLedger.previewLine(
      _snapshot(stored),
      _month,
      const PayrollVariables(staffMemberId: 'm-1'),
      entries: entries,
    );

    test('garde les saisies de la tablette', () {
      expect(
        preview([_entry('a', 500)])!.deductions.custom.single.takenInCents,
        500,
      );
    });

    test('une saisie refusée ne compte pas', () {
      final line = preview([_entry('a', 500, state: RecordSyncState.failed)])!;

      expect(line.deductions.custom, isEmpty);
    });

    test('les montants en cours remplacent ceux rangés', () {
      final line = preview([_entry('a', 500)], entries: [_entry('a', 900)])!;

      expect(line.deductions.customInCents, 900);
    });
  });

  group('un champ de la modale', () {
    PayrollCustomField field(PayrollDeductionEntry? entry) =>
        PayrollCustomField.of(_cards, entry, 'USD');

    test('resté à 0 : rien ne part', () {
      expect(field(null).changed('m-1'), isNull);
    });

    test('inchangé : rien ne part', () {
      expect(field(_entry('a', 500)).changed('m-1'), isNull);
    });

    test('un montant part, dans la devise de la ligne', () {
      final input = field(null)..controller.text = '5';

      final entry = input.changed('m-1')!;
      expect(entry.amountInCents, 500);
      expect(entry.currency, 'USD');
    });

    test('ramené à 0 : part avec 0', () {
      final input = field(_entry('a', 500))..controller.text = '0';

      expect(input.changed('m-1')!.amountInCents, 0);
    });

    test('vidé : part avec 0', () {
      final input = field(_entry('a', 500))..controller.clear();

      expect(input.changed('m-1')!.amountInCents, 0);
    });

    test('un texte illisible bloque, sans rien écrire', () {
      final input = field(null)..controller.text = 'abc';

      expect(input.invalid, isTrue);
      expect(input.changed('m-1'), isNull);
    });

    test('autre devise : laissé vide, rien ; 0 tapé, efface', () {
      final foreign = field(_entry('a', 500, currency: 'CDF'));
      expect(foreign.foreign, isTrue);
      expect(foreign.controller.text, isEmpty);
      expect(foreign.changed('m-1'), isNull);

      foreign.controller.text = '0';
      final entry = foreign.changed('m-1')!;
      expect(entry.amountInCents, 0);
      expect(entry.currency, 'USD');
    });

    test('autre devise ressaisie : part dans celle de la ligne', () {
      final foreign = field(_entry('a', 500, currency: 'CDF'))
        ..controller.text = '5';

      expect(foreign.changed('m-1')!.currency, 'USD');
    });

    test('refusée : ne repart pas sans geste, ressaisie elle repart', () {
      final refused = field(_entry('a', 500, state: RecordSyncState.failed));

      expect(refused.controller.text, isEmpty);
      expect(refused.changed('m-1'), isNull);
      expect(refused.preview('m-1').amountInCents, 0);

      refused.controller.text = '5';
      expect(refused.changed('m-1')!.amountInCents, 500);
    });

    test('refusée avec valeur serveur : s\'ouvre dessus, 0 la retire', () {
      final refused = field(
        const PayrollDeductionEntry(
          staffMemberId: 'm-1',
          deductionTypeId: 'a',
          amountInCents: 800,
          currency: 'USD',
          serverAmountInCents: 500,
          serverCurrency: 'USD',
          syncState: RecordSyncState.failed,
        ),
      );

      expect(refused.changed('m-1'), isNull);
      refused.controller.clear();
      expect(refused.changed('m-1')!.amountInCents, 0);
    });

    test('verrouillée en autre devise : la mise à 0 part', () {
      final locked = PayrollCustomField.of(
        _old,
        _entry('z', 500, currency: 'CDF'),
        'USD',
      );

      expect(locked.clearable, isTrue);
      locked.clear();
      expect(locked.clearable, isFalse);
      expect(locked.changed('m-1')!.amountInCents, 0);
    });
  });

  group('enregistrement', () {
    late _MockRepository repository;

    setUpAll(() {
      registerFallbackValue(<PayrollDeductionEntry>[]);
      registerFallbackValue(const PayrollVariables(staffMemberId: ''));
    });

    setUp(() {
      repository = _MockRepository();
      when(
        () => repository.saveEntries(
          any(),
          variables: any(named: 'variables'),
          entries: any(named: 'entries'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    });

    Future<Either<Failure, Unit>> save(
      PayrollMonthView view,
      List<PayrollDeductionEntry> entries,
    ) => SavePayrollDeductionsUseCase(repository)(
      view,
      const PayrollVariables(staffMemberId: 'm-1'),
      entries,
      catalog: const [_cards, _old],
    );

    PayrollRule? rule(Either<Failure, Unit> result) => result.fold(
      (failure) => (failure as PayrollRuleFailure).rule,
      (_) => null,
    );

    test('en brouillon, tout part ensemble', () async {
      expect(
        await save(_draft, [_entry('a', 500)]),
        isA<Right<Failure, Unit>>(),
      );
    });

    test('hors brouillon : refusé', () async {
      expect(
        rule(await save(_submitted, [_entry('a', 500)])),
        PayrollRule.notEditable,
      );
    });

    test('rubrique archivée : montant refusé, 0 accepté', () async {
      expect(
        rule(await save(_draft, [_entry('z', 500)])),
        PayrollRule.deductionTypeArchived,
      );
      expect(await save(_draft, [_entry('z', 0)]), isA<Right<Failure, Unit>>());
    });

    test('montant négatif : refusé', () async {
      expect(
        rule(await save(_draft, [_entry('a', -1)])),
        PayrollRule.invalidAmount,
      );
    });
  });

  group('la modale', () {
    Future<PayrollVariablesResult?> Function() open(
      WidgetTester tester, {
      required List<PayrollDeductionType> types,
      List<PayrollDeductionEntry> entries = const [],
      PayrollLine? preview,
    }) {
      return () async {
        PayrollVariablesResult? result;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await PayrollVariablesDialog.show(
                      context,
                      PayrollVariablesDialog(
                        name: 'Ruth',
                        line: _line,
                        current: const PayrollVariables(staffMemberId: 'm-1'),
                        settings: PayrollSettings.defaults,
                        deductionTypes: types,
                        entries: entries,
                        preview: (_, _) => preview ?? _line,
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
      };
    }

    testAtReferenceFormats('Six rubriques à saisir', (tester, format) async {
      await open(
        tester,
        types: [
          for (var i = 0; i < 6; i++)
            PayrollDeductionType(
              id: 't$i',
              label: 'Une rubrique au libellé déjà assez long $i',
              sortOrder: i,
            ),
          _old,
        ],
        entries: [_entry('z', 500)],
      )();

      expect(find.text('Retenues de l\'école'), findsOneWidget);
      expect(find.text('Ancienne (archivée)'), findsOneWidget);
    });

    testWidgets('une archivée sans montant reste cachée', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(tester, types: const [_cards, _old])();

      expect(find.text('Cartes'), findsOneWidget);
      expect(find.text('Ancienne (archivée)'), findsNothing);
    });

    testWidgets('une archivée avec montant se met à 0, sans autre saisie', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(tester, types: const [_old], entries: [_entry('z', 500)])();

      expect(find.byType(TextField).evaluate().length, greaterThan(0));
      await tester.ensureVisible(find.text('Mettre à 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mettre à 0'));
      await tester.pump();

      expect(find.text('Ancienne (archivée)'), findsOneWidget);
    });

    testWidgets('« saisi X, retenu Y » sur une rubrique rognée', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(
        tester,
        types: const [_cards],
        entries: [_entry('a', 500)],
        preview: const PayrollLine(
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
      )();

      expect(find.textContaining('Saisi'), findsOneWidget);
      expect(find.textContaining('retenu'), findsOneWidget);
    });

    testWidgets('une saisie refusée dit pourquoi sur son champ', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(
        tester,
        types: const [_cards],
        entries: [
          _entry(
            'a',
            500,
            state: RecordSyncState.failed,
            code: PayrollDeductionCodes.archived,
          ),
        ],
      )();

      expect(find.textContaining('Montant refusé'), findsOneWidget);
    });

    testWidgets('une autre devise le dit sur son champ', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await open(
        tester,
        types: const [_cards],
        entries: [_entry('a', 500, currency: 'CDF')],
      )();

      expect(find.textContaining('dans une autre devise'), findsOneWidget);
    });
  });
}
