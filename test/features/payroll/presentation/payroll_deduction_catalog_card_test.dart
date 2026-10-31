import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction_codes.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_settings_page.dart';

import '../../../test_helpers/reference_formats.dart';
import 'payroll_screen_harness.dart';

class _MockDeductions extends Mock implements PayrollDeductionRepository {}

PayrollSnapshot _snapshot(
  List<PayrollDeductionType> types, {
  String? frozenCustomOn,
}) => PayrollSnapshot(
  members: const [],
  contractsByMember: const {},
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: const {},
  variables: const {},
  deductionTypes: types,
  deductions: frozenCustomOn == null
      ? const {}
      : {
          '2026-10': {
            'm-1': [
              PayrollDeductionEntry(
                staffMemberId: 'm-1',
                deductionTypeId: frozenCustomOn,
                amountInCents: 500,
                currency: 'USD',
              ),
            ],
          },
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

void main() {
  const direction = [Perm.hrPayRead, Perm.hrPayWrite, Perm.hrPayManage];
  const cards = PayrollDeductionType(
    id: 'a',
    code: 'CARTE',
    label: 'Frais des cartes',
    currency: 'USD',
    sortOrder: 10,
    serverKnown: true,
  );
  late _MockDeductions deductions;

  setUpAll(() => registerFallbackValue(<PayrollDeductionType>[]));

  setUp(() {
    deductions = _MockDeductions();
    when(() => deductions.newTypeId()).thenReturn('new');
    when(
      () => deductions.saveTypes(any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  Future<void> tall(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testAtReferenceFormats('Carte des rubriques', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot([
        for (var i = 0; i < 6; i++)
          PayrollDeductionType(
            id: 't$i',
            label: 'Une rubrique au libellé déjà assez long $i',
            sortOrder: i,
          ),
        const PayrollDeductionType(
          id: 'old',
          label: 'Ancienne',
          sortOrder: 90,
          archived: true,
        ),
      ]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(find.text('Retenues de l\'école'), findsOneWidget);
  });

  testAtReferenceFormats('Formulaire d une rubrique', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const []),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    await tester.ensureVisible(find.text('Ajouter une rubrique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une rubrique'));
    await tester.pumpAndSettle();

    expect(find.text('Montant par défaut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la direction crée une rubrique', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const [cards]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    await tester.tap(find.text('Ajouter une rubrique'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'tenue');
    await tester.enterText(fields.at(1), 'Tenue');
    await tester.enterText(fields.at(2), 'Tenue de travail');
    await tester.enterText(fields.at(3), '5');
    await tester.pump();
    await tester.tap(find.text('Enregistrer').last);
    await tester.pumpAndSettle();

    final saved =
        verify(() => deductions.saveTypes(captureAny())).captured.single
            as List<PayrollDeductionType>;
    final type = saved.single;
    expect(type.code, 'TENUE');
    expect(type.label, 'Tenue');
    expect(type.description, 'Tenue de travail');
    expect(type.currency, PayrollSettings.defaults.firstCurrency);
    expect(type.defaultAmountInCents, 500);
    expect(type.sortOrder, 20);
  });

  testWidgets('le formulaire demande un code et ouvre le défaut à 0', (
    tester,
  ) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const []),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    await tester.tap(find.text('Ajouter une rubrique'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(fields.at(3)).controller!.text, '0');
    await tester.enterText(fields.at(1), 'Tenue');
    await tester.tap(find.text('Enregistrer').last);
    await tester.pump();

    expect(
      find.text('2 à 12 caractères : lettres, chiffres, - ou _.'),
      findsOneWidget,
    );
    verifyNever(() => deductions.saveTypes(any()));
  });

  testWidgets('une rubrique utilisée garde son code à la modification', (
    tester,
  ) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const [cards], frozenCustomOn: cards.id),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    await tester.tap(find.byTooltip('Actions de la rubrique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cette rubrique a servi : son code et sa devise ne changent plus.',
      ),
      findsOneWidget,
    );
    final code = find
        .descendant(of: find.byType(Dialog), matching: find.byType(TextField))
        .first;
    expect(tester.widget<TextField>(code).readOnly, isTrue);
  });

  testWidgets('un libellé vide ne part pas', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const []),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(find.text('Aucune rubrique pour l\'instant.'), findsOneWidget);
    await tester.tap(find.text('Ajouter une rubrique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer').last);
    await tester.pump();

    expect(find.text('Le libellé est obligatoire.'), findsOneWidget);
    verifyNever(() => deductions.saveTypes(any()));
  });

  testWidgets('six rubriques par devise : l\'ajout se ferme et dit pourquoi', (
    tester,
  ) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot([
        for (final currency in PayrollSettings.defaults.byCurrency.keys)
          for (var i = 0; i < 6; i++)
            PayrollDeductionType(
              id: '$currency$i',
              label: 'R$i',
              currency: currency,
              sortOrder: i,
            ),
      ]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(
      find.text(
        'Six rubriques actives au plus par devise : archivez-en une pour '
        'continuer.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('une devise pleine laisse créer dans une autre', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot([
        for (var i = 0; i < 6; i++)
          PayrollDeductionType(
            id: 't$i',
            label: 'R$i',
            currency: PayrollSettings.defaults.firstCurrency,
            sortOrder: i,
          ),
      ]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(find.textContaining('Six rubriques actives'), findsNothing);
  });

  testWidgets('la ligne dit le code et le montant par défaut', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const [
        PayrollDeductionType(
          id: 'a',
          code: 'CARTE',
          label: 'Frais des cartes',
          description: 'Badge du personnel',
          currency: 'USD',
          defaultAmountInCents: 500,
          sortOrder: 10,
        ),
      ]),
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(find.textContaining('CARTE ·'), findsOneWidget);
    expect(find.text('Badge du personnel'), findsOneWidget);
  });

  testWidgets('l\'économe consulte, sans aucun geste', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const [cards]),
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(find.text('Frais des cartes'), findsOneWidget);
    expect(find.text('Ajouter une rubrique'), findsNothing);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
  });

  testWidgets('une création refusée se nomme sur sa ligne', (tester) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot(const [
        PayrollDeductionType(
          id: 'a',
          label: 'Doublon',
          sortOrder: 10,
          syncState: RecordSyncState.failed,
          syncErrorCode: PayrollDeductionCodes.labelTaken,
        ),
      ]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(
      find.text('Une rubrique active de cette devise porte déjà ce libellé.'),
      findsOneWidget,
    );
  });
}
