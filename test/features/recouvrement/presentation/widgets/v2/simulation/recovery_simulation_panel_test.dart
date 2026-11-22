import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_cards.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_table.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'simulation_test_harness.dart';

void main() {
  final tapped = <RecoverySimulationRow>[];
  final thresholds = <int>[];
  var changes = 0;

  setUp(() {
    tapped.clear();
    thresholds.clear();
    changes = 0;
  });

  Widget panel(
    RecoveryDashboard dashboard, {
    RecoveryRuleKind rule = RecoveryRuleKind.somePayment,
    int? threshold,
    int below = 60,
  }) => RecoverySimulationPanel(
    dashboard: dashboard,
    rule: rule,
    thresholdInCents: threshold,
    unmanageableBelow: below,
    onUnmanageableChanged: thresholds.add,
    onChangeRule: () => changes++,
    onClassTapped: tapped.add,
  );

  testWidgets('en-tête, critère en lecture, « Changer » remonte à E (I14)', (
    tester,
  ) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()));

    expect(
      find.text('Simulation : si on renvoyait les élèves pas en ordre'),
      findsOneWidget,
    );
    expect(find.text("N'ont rien payé"), findsOneWidget);
    expect(find.text('CRITÈRE (LE MÊME QUE CI-DESSUS)'), findsOneWidget);
    await tester.tap(find.text('Changer'));
    expect(changes, 1);
  });

  testWidgets('le curseur va de 30 à 90 par pas de 5 (I15)', (tester) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()));

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 30);
    expect(slider.max, 90);
    expect(slider.divisions, 12);
    slider.onChanged!(65);
    expect(thresholds, [65]);
  });

  testWidgets('quatre chiffres : effectif, visés, restant, ingérables', (
    tester,
  ) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()));

    expect(find.text('478'), findsOneWidget);
    expect(find.text('235'), findsOneWidget);
    expect(find.text('243'), findsOneWidget);
    expect(find.text("50 % de l'effectif conservé"), findsOneWidget);
    expect(find.text('Aucun versement sur les frais retenus'), findsOneWidget);
    // Sous 60 % : 2ème, 3ème, 1ère humanités, 8ème, 7ème EB, 6ème, 5ème.
    expect(find.text('7'), findsWidgets);
    expect(find.text('2ème humanités, 3ème humanités…'), findsOneWidget);
  });

  testWidgets('aucune classe sous le seuil', (tester) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture(), below: 30));
    // 2ème, 3ème, 1ère humanités restent sous 30 %.
    expect(find.text('aucune sous le seuil'), findsNothing);

    final calm = withSimulation(
      recoveryDashboardFixture(),
      simulation: simulationOf([
        simRow('c1', '1ère', headcount: 30, targeted: 3),
      ]),
    );
    await pumpSimulation(tester, panel(calm));
    expect(find.text('aucune sous le seuil'), findsOneWidget);
  });

  testWidgets('les trois critères (A11)', (tester) async {
    final d = recoveryDashboardFixture();
    await pumpSimulation(tester, panel(d, rule: RecoveryRuleKind.fullySettled));
    expect(find.text("N'ont pas tout soldé"), findsOneWidget);
    expect(find.text('Rien payé ou paiement partiel'), findsOneWidget);

    await pumpSimulation(
      tester,
      panel(d, rule: RecoveryRuleKind.atLeast, threshold: 15000),
    );
    expect(find.textContaining('Ont payé moins que 150'), findsOneWidget);

    // « Au moins » sans montant : la règle par défaut (R8).
    await pumpSimulation(tester, panel(d, rule: RecoveryRuleKind.atLeast));
    expect(find.text("N'ont rien payé"), findsOneWidget);
  });

  test('recoveryCriterionLabel suit effectiveRule', () {
    final l10n = AppLocalizationsFr();
    expect(
      recoveryCriterionLabel(
        const RecoveryQuestion(
          feeCodes: ['TUITION'],
          rule: RecoveryRuleKind.atLeast,
        ),
        l10n,
      ),
      "N'ont rien payé",
    );
    expect(
      recoveryCriterionLabel(
        const RecoveryQuestion(
          feeCodes: ['TUITION'],
          rule: RecoveryRuleKind.atLeast,
          thresholdInCents: 15000,
        ),
        l10n,
        currency: 'USD',
      ),
      startsWith('Ont payé moins que 150'),
    );
  });

  testWidgets('tableau dès 600 : l\'ordre du serveur, une ligne s\'ouvre', (
    tester,
  ) async {
    final d = recoveryDashboardFixture();
    await pumpSimulation(tester, panel(d));

    expect(find.byType(RecoverySimulationTable), findsOneWidget);
    expect(find.text('−32'), findsNWidgets(2));
    final first = tester.getTopLeft(find.text('2ème humanités').last);
    final last = tester.getTopLeft(find.text('1ère maternelle'));
    expect(first.dy, lessThan(last.dy));
    await tester.tap(find.text('1ère maternelle'));
    expect(tapped.single.classroomId, 'c1');
  });

  testWidgets('« Non affectés » en dernier, sans verdict ; sans visé, inerte', (
    tester,
  ) async {
    final d = withSimulation(
      recoveryDashboardFixture(),
      simulation: simulationOf([
        simRow(null, 'Non affectés', headcount: 6, targeted: 4),
        simRow('c1', '1ère A', headcount: 30, targeted: 20),
        simRow('c2', '2ème A', headcount: 30, targeted: 0),
      ]),
    );
    await pumpSimulation(tester, panel(d));

    final names = ['1ère A', '2ème A', 'Non affectés'];
    final ys = [for (final n in names) tester.getTopLeft(find.text(n).last).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(find.text('Ingérable'), findsOneWidget);
    expect(find.text('Tenable'), findsOneWidget);
    await tester.tap(find.text('2ème A').last);
    expect(tapped, isEmpty);
    await tester.tap(find.text('Non affectés').last);
    expect(tapped.single.isUnassigned, isTrue);
  });

  testWidgets('sous 600 : 6 cartes puis « Voir les 7 autres classes » (A12)', (
    tester,
  ) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()), width: 360);

    expect(find.byType(RecoverySimulationCards), findsOneWidget);
    expect(find.text('1ère maternelle'), findsNothing);
    await tester.tap(find.text('Voir les 7 autres classes'));
    await tester.pumpAndSettle();
    expect(find.text('1ère maternelle'), findsOneWidget);
    final less = find.text('Ne garder que les 6 classes les plus touchées');
    await tester.ensureVisible(less);
    await tester.tap(less);
    await tester.pumpAndSettle();
    expect(find.text('1ère maternelle'), findsNothing);
    final first = find.text('2ème humanités').last;
    await tester.ensureVisible(first);
    await tester.tap(first);
    expect(tapped.single.classroomId, 'c12');
  });

  testWidgets('entre 600 et 680 : le tableau défile, ascenseur visible (A13)', (
    tester,
  ) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()), width: 640);

    expect(find.byType(RecoverySimulationTable), findsOneWidget);
    final bar = tester.widget<Scrollbar>(
      find.descendant(
        of: find.byType(RecoverySimulationTable),
        matching: find.byType(Scrollbar),
      ),
    );
    expect(bar.thumbVisibility, isTrue);
  });

  testWidgets('note : rien de perdu, ce qui est abandonné', (tester) async {
    await pumpSimulation(tester, panel(recoveryDashboardFixture()));
    expect(
      find.textContaining(
        'le renvoi ne ferait perdre aucune recette encaissée',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('56'), findsWidgets);
  });

  testWidgets('note mixte : par devise, jamais additionnés', (tester) async {
    final d = withSimulation(
      recoveryMixedDashboardFixture(),
      simulation: simulationOf(
        [simRow('c1', '1ère A', headcount: 30, targeted: 20)],
        lost: const [Money(100000, 'CDF'), Money(1500, 'USD')],
        abandoned: const [Money(500000, 'CDF'), Money(24000, 'USD')],
      ),
    );
    await pumpSimulation(tester, panel(d));

    final note = find.textContaining('Le renvoi ferait aussi perdre');
    expect(note, findsOneWidget);
    final text = tester.widget<Text>(note).data!;
    expect(text, contains(' et '));
    expect(text, contains('FC'));
    expect(text, contains(r'$'));
  });

  testWidgets('personne de visé : pas de note', (tester) async {
    final d = withSimulation(
      recoveryDashboardFixture(),
      simulation: simulationOf([
        simRow('c1', '1ère A', headcount: 30, targeted: 0),
      ]),
    );
    await pumpSimulation(tester, panel(d));
    expect(find.textContaining('Touchez une classe'), findsNothing);
  });

  for (final scale in [1.0, 1.3]) {
    for (final width in simulationWidths) {
      testWidgets('tient à $width dp, texte ×$scale', (tester) async {
        await pumpSimulation(
          tester,
          panel(recoveryMixedDashboardFixture()),
          width: width,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
