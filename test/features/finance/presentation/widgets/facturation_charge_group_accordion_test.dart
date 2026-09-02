import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_grouping.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_progress_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_group_accordion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'accordéon d'une nature de frais (GF-3).
void main() {
  StudentCharge charge({
    required String id,
    String feeCode = 'TUITION',
    String label = '',
    String? tariffCode,
    double expected = 50000,
    double paid = 0,
    double pending = 0,
    String currency = 'CDF',
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeTariffCode: tariffCode,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    amountPaidPendingInCents: pending,
    currency: currency,
    status: StudentChargeStatus.due,
  );

  Future<void> pump(
    WidgetTester tester,
    List<StudentCharge> charges, {
    bool expanded = false,
    String? schoolTitle,
    VoidCallback? onToggle,
    ValueChanged<StudentCharge>? onView,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FacturationChargeGroupAccordion(
                group: groupChargesByFeeCode(charges).single,
                schoolTitle: schoolTitle,
                expanded: expanded,
                onToggle: onToggle ?? () {},
                onViewChargeRequested: onView ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('un groupe d\'une seule tranche', () {
    testWidgets('reste une ligne nue, sans chevron', (tester) async {
      // Un accordéon dont le corps répète son en-tête ferait payer un geste
      // pour ne rien découvrir.
      await pump(tester, [charge(id: '1', label: 'Frais d\'examen')]);

      expect(find.byType(FacturationChargeLine), findsOneWidget);
      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
    });

    testWidgets('son clic ouvre le DÉTAIL, pas un pli', (tester) async {
      StudentCharge? opened;
      var toggled = 0;
      await pump(
        tester,
        [charge(id: '1', label: 'Frais d\'examen')],
        onToggle: () => toggled++,
        onView: (c) => opened = c,
      );

      await tester.tap(find.byType(FacturationChargeLine));
      await tester.pumpAndSettle();

      expect(opened?.id, '1');
      expect(toggled, 0);
    });
  });

  group('un groupe de plusieurs tranches', () {
    final tranches = [
      charge(id: '1', label: 'Minerval — 1/2', tariffCode: 'T1', paid: 50000),
      charge(id: '2', label: 'Minerval — 2/2', tariffCode: 'T2'),
    ];

    testWidgets('replié : l\'en-tête seul, aucune tranche', (tester) async {
      await pump(tester, tranches, schoolTitle: 'Frais scolaires');

      expect(find.text('Frais scolaires · 2 tranches'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
      expect(find.byType(FacturationChargeLine), findsNothing);
      expect(find.text('Minerval — 1/2 (T1)'), findsNothing);
    });

    testWidgets('déplié : les tranches, dans l\'ordre reçu', (tester) async {
      await pump(tester, tranches, expanded: true);

      expect(find.byType(FacturationChargeLine), findsNWidgets(2));
      expect(find.text('Minerval — 1/2 (T1)'), findsOneWidget);
      expect(find.text('Minerval — 2/2 (T2)'), findsOneWidget);
    });

    testWidgets('le clic de l\'en-tête plie, il n\'ouvre rien', (tester) async {
      var toggled = 0;
      StudentCharge? opened;
      await pump(
        tester,
        tranches,
        onToggle: () => toggled++,
        onView: (c) => opened = c,
      );

      await tester.tap(find.text('Frais de scolarité · 2 tranches'));
      await tester.pumpAndSettle();

      expect(toggled, 1);
      expect(
        opened,
        isNull,
        reason: 'Il n\'existe pas de « détail de nature ».',
      );
    });

    testWidgets('le clic d\'une tranche ouvre SON détail', (tester) async {
      StudentCharge? opened;
      await pump(tester, tranches, expanded: true, onView: (c) => opened = c);

      await tester.tap(find.text('Minerval — 2/2 (T2)'));
      await tester.pumpAndSettle();

      expect(opened?.id, '2');
    });

    testWidgets('une seule jauge quand tout est dans la même devise', (
      tester,
    ) async {
      await pump(tester, tranches);

      expect(find.byType(FeeProgressBar), findsOneWidget);
    });
  });

  group('multi-devise', () {
    testWidgets('une jauge PAR DEVISE, jamais une seule pour les deux', (
      tester,
    ) async {
      // Une jauge unique sur des dollars ET des francs fabriquerait un
      // pourcentage que personne ne peut vérifier.
      await pump(tester, [
        charge(id: '1', expected: 50000, paid: 25000),
        charge(id: '2', expected: 40000, paid: 40000, currency: 'USD'),
      ]);

      expect(find.byType(FeeProgressBar), findsNWidgets(2));
    });
  });

  testWidgets('un versement pas encore remonté se signale sur l\'en-tête', (
    tester,
  ) async {
    await pump(tester, [
      charge(id: '1', expected: 50000, paid: 0, pending: 20000),
      charge(id: '2', expected: 50000),
    ]);

    expect(find.byIcon(Icons.sync_outlined), findsOneWidget);
  });

  testWidgets('reduced-motion : rien ne s\'anime, tout reste lisible', (
    tester,
  ) async {
    await pump(
      tester,
      [charge(id: '1', label: 'A'), charge(id: '2', label: 'B')],
      expanded: true,
      reduceMotion: true,
    );

    expect(find.byType(FacturationChargeLine), findsNWidgets(2));
  });
}
