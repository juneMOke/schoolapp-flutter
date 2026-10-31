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

PayrollSnapshot _snapshot(List<PayrollDeductionType> types) => PayrollSnapshot(
  members: const [],
  contractsByMember: const {},
  settings: PayrollSettings.defaults,
  profiles: const {},
  headers: const {},
  variables: const {},
  deductionTypes: types,
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
    label: 'Frais des cartes',
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
    await tester.enterText(find.byType(TextField).last, 'Tenue');
    await tester.pump();
    await tester.tap(find.text('Enregistrer').last);
    await tester.pumpAndSettle();

    final saved =
        verify(() => deductions.saveTypes(captureAny())).captured.single
            as List<PayrollDeductionType>;
    expect(saved.single.label, 'Tenue');
    expect(saved.single.sortOrder, 20);
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

  testWidgets('six rubriques actives : l\'ajout se ferme et dit pourquoi', (
    tester,
  ) async {
    await tall(tester);
    await pumpPayrollScreen(
      tester,
      snapshot: _snapshot([
        for (var i = 0; i < 6; i++)
          PayrollDeductionType(id: 't$i', label: 'R$i', sortOrder: i),
      ]),
      permissions: direction,
      deductions: deductions,
      child: const PayrollSettingsScreen(),
    );

    expect(
      find.text(
        'Six rubriques actives au plus : archivez-en une pour continuer.',
      ),
      findsOneWidget,
    );
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
      find.text('Une rubrique active porte déjà ce libellé.'),
      findsOneWidget,
    );
  });
}
