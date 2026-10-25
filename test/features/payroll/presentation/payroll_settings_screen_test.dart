import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_advances_page.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_settings_page.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import 'payroll_screen_harness.dart';

/// RH · Paie ▸ Configuration (le barème) et ▸ Avances & prêts, devenus des
/// sous-modules.
void main() {
  setUpAll(() => registerFallbackValue(PayrollSettings.defaults));

  const direction = [Perm.hrPayRead, Perm.hrPayWrite, Perm.hrPayManage];

  final snapshot = PayrollSnapshot(
    members: [member('m-1', lastName: 'Mayala', firstName: 'Ruth')],
    contractsByMember: const {},
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: const {
      '2026-09': PayrollHeader(
        id: 'p-2026-09',
        month: '2026-09',
        status: PayrollStatus.validated,
        validationGestureId: 'g-2026-09',
      ),
      '2026-10': PayrollHeader(
        id: 'p-2026-10',
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
    schoolYears: const [(start: '2025-09-01', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  Finder input(String label) => find.byWidgetPredicate(
    (widget) => widget is EteeloTextInput && widget.label == label,
  );
  Finder field(String label) =>
      find.descendant(of: input(label), matching: find.byType(TextField));

  testAtReferenceFormats('Configuration du barème', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      permissions: direction,
      child: const PayrollSettingsScreen(),
    );

    expect(find.text('Mois de salaire'), findsOneWidget);
    expect(find.text('Barème à jour'), findsOneWidget);
  });

  testAtReferenceFormats('Avances & prêts', (tester, format) async {
    await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      child: const PayrollAdvancesScreen(),
    );

    expect(find.text('Aucune avance accordée'), findsOneWidget);
  });

  testWidgets(
    'l économe consulte : bandeau, champs grisés, rien à enregistrer',
    (tester) async {
      await pumpPayrollScreen(
        tester,
        snapshot: snapshot,
        child: const PayrollSettingsScreen(),
      );

      expect(
        find.text('Lecture seule — seule la direction modifie le barème.'),
        findsOneWidget,
      );
      expect(find.text('Enregistrer le barème'), findsNothing);
      final hours = tester.widget<EteeloTextInput>(
        input("Heures d'un mois plein"),
      );
      expect(hours.enabled, isFalse);
    },
  );

  testWidgets('la direction modifie : état, bornes, puis enregistrement', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      permissions: direction,
      child: const PayrollSettingsScreen(),
    );
    when(
      () => pumped.repository.saveSettings(any()),
    ).thenAnswer((_) async => const Right(unit));

    await tester.enterText(field("Jours d'un mois plein"), '0');
    await tester.pump();
    expect(find.text('Entre 1 et 31'), findsOneWidget);
    expect(
      find.text('Corrigez les champs en rouge avant d\'enregistrer.'),
      findsOneWidget,
    );

    await tester.enterText(field("Jours d'un mois plein"), '22');
    await tester.pump();
    // Le brouillon d'octobre ; septembre est validé, il garde son barème.
    expect(
      find.text(
        'Modifications non enregistrées · s\'appliqueront à 1 paie en cours',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Enregistrer le barème'));
    await tester.pumpAndSettle();

    final saved =
        verify(
              () => pumped.repository.saveSettings(captureAny()),
            ).captured.single
            as PayrollSettings;
    expect(saved.workDaysDivisor, 22);
    expect(saved.monthlyHoursDivisor, 173);
    expect(saved.overtimeMultiplierPermille, 1300);
  });

  testWidgets('rétablir remplit le brouillon, sans rien enregistrer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pumped = await pumpPayrollScreen(
      tester,
      snapshot: snapshot,
      permissions: direction,
      child: const PayrollSettingsScreen(),
    );

    await tester.enterText(field("Heures d'un mois plein"), '160');
    await tester.pump();
    await tester.tap(find.text('Rétablir les valeurs par défaut'));
    await tester.pump();

    expect(find.text('Barème à jour'), findsOneWidget);
    verifyNever(() => pumped.repository.saveSettings(any()));
  });
}
