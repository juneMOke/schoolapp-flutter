import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_key_figures_section.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'figures_test_harness.dart';

/// Bloc B · chiffres de tête (spec §4.6 B, R5, A2, A3, A15, A17).
void main() {
  final tapped = <StudentChargeStatus>[];
  setUp(tapped.clear);

  Widget section({bool mixed = false}) => RecoveryKeyFiguresSection(
    dashboard: mixed
        ? recoveryMixedDashboardFixture()
        : recoveryDashboardFixture(),
    onSituationTapped: tapped.add,
  );

  Finder inCard(String key, Finder f) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: f);

  testWidgets('A2 — attendu, perçu (anneau 28 %), reste et situation', (
    tester,
  ) async {
    await pumpFigures(tester, section());

    expect(
      inCard('recovery-figure-expected', find.text(money(13092000, 'USD'))),
      findsOneWidget,
    );
    expect(find.text('Frais dus en dollars'), findsOneWidget);
    expect(
      inCard('recovery-figure-collected', find.text(money(3612300, 'USD'))),
      findsOneWidget,
    );
    expect(find.text('28\u00a0%'), findsOneWidget);
    expect(find.text('104 élèves ont tout soldé'), findsOneWidget);
    expect(
      inCard('recovery-figure-remaining', find.text(money(9479700, 'USD'))),
      findsOneWidget,
    );
    expect(find.text('Auprès de 374 élèves pas soldés'), findsOneWidget);

    expect(find.text('SITUATION DES 478 ÉLÈVES'), findsOneWidget);
    for (final n in ['315', '59', '104']) {
      expect(inCard('recovery-figure-situation', find.text(n)), findsOneWidget);
    }
    expect(find.text("N'a rien payé"), findsOneWidget);
    expect(find.text('Partiellement payé'), findsOneWidget);
    expect(find.text('Tout soldé'), findsOneWidget);
  });

  testWidgets('A3 — mixte : deux montants par pavé, dollars puis francs, '
      'pas d’anneau', (tester) async {
    await pumpFigures(tester, section(mixed: true));

    final usd = money(13092000, 'USD');
    final cdf = money(221500000, 'CDF');
    final expected = find.byKey(const ValueKey('recovery-figure-expected'));
    expect(inCard('recovery-figure-expected', find.text(usd)), findsOneWidget);
    expect(inCard('recovery-figure-expected', find.text(cdf)), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.descendant(of: expected, matching: find.text(usd)))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.descendant(of: expected, matching: find.text(cdf)))
            .dy,
      ),
    );
    expect(
      inCard('recovery-figure-collected', find.text(money(97500000, 'CDF'))),
      findsOneWidget,
    );
    expect(
      inCard('recovery-figure-remaining', find.text(money(124000000, 'CDF'))),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Francs et dollars, jamais additionnés'), findsOneWidget);
  });

  testWidgets('A15 — chaque ligne de Situation donne sa situation, 48 dp', (
    tester,
  ) async {
    await pumpFigures(tester, section());

    for (final (label, status) in [
      ("N'a rien payé", StudentChargeStatus.due),
      ('Partiellement payé', StudentChargeStatus.partial),
      ('Tout soldé', StudentChargeStatus.paid),
    ]) {
      final row = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text(label));
      expect(tapped.last, status);
    }
    expect(tapped, hasLength(3));
  });

  test('bande fluide : 1 · 2×2 · 2×2 · 3+1 · 4 colonnes', () {
    expect(RecoveryKeyFiguresSection.columnsFor(328), 1);
    expect(RecoveryKeyFiguresSection.columnsFor(552), 2);
    expect(RecoveryKeyFiguresSection.columnsFor(668), 2);
    expect(RecoveryKeyFiguresSection.columnsFor(708), 2);
    expect(RecoveryKeyFiguresSection.columnsFor(828), 3);
    expect(RecoveryKeyFiguresSection.columnsFor(1112), 4);
    expect(RecoveryKeyFiguresSection.columnsFor(1148), 4);
  });

  testWidgets('3 + 1 à 828 : la carte Situation passe seule dessous', (
    tester,
  ) async {
    await pumpFigures(tester, section(), width: 828);
    final y = [
      for (final k in [
        'recovery-figure-expected',
        'recovery-figure-collected',
        'recovery-figure-remaining',
        'recovery-figure-situation',
      ])
        tester.getTopLeft(find.byKey(ValueKey(k))).dy,
    ];
    expect(y[0], y[1]);
    expect(y[1], y[2]);
    expect(y[3], greaterThan(y[0]));
    // Les pavés d'une rangée ont la même hauteur.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('recovery-figure-expected')))
          .height,
      tester
          .getSize(find.byKey(const ValueKey('recovery-figure-remaining')))
          .height,
    );
  });

  for (final width in [328.0, 360.0, 600.0, 800.0, 1280.0]) {
    for (final scale in [1.0, 1.3]) {
      for (final mixed in [false, true]) {
        testWidgets(
          'aucun débordement à $width dp, texte ×$scale, mixte $mixed',
          (tester) async {
            await pumpFigures(
              tester,
              section(mixed: mixed),
              width: width,
              height: 2000,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
