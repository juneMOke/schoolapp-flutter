import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_insight_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_insights_row.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'simulation_test_harness.dart';

RecoveryClassFeeRow _class(String id, String name, int rate) =>
    RecoveryClassFeeRow(
      classroomId: id,
      classroomName: name,
      billedStudents: 10,
      settledStudents: 2,
      noPaymentStudents: 3,
      due: const Money(100000, 'USD'),
      outstanding: const Money(50000, 'USD'),
      ratePercent: rate,
    );

void main() {
  var controls = 0;
  setUp(() => controls = 0);

  Widget row(RecoveryDashboard d, {String? fee = 'TUITION', int below = 60}) =>
      RecoveryInsightsRow(
        dashboard: d,
        rankingFeeCode: fee,
        unmanageableBelow: below,
        onControlStudents: () => controls++,
      );

  testWidgets('le frais le plus en retard, et « Contrôler les élèves »', (
    tester,
  ) async {
    await pumpSimulation(tester, row(recoveryMixedDashboardFixture()));

    // Scolarité (28 %) passe avant l'inscription en francs (44 %).
    expect(
      find.textContaining('Frais de scolarité plafonne à 28 % de recouvrement'),
      findsOneWidget,
    );
    await tester.tap(find.text('Contrôler les élèves'));
    expect(controls, 1);
  });

  testWidgets('écart entre classes : du meilleur au moins bon', (tester) async {
    final d = recoveryDashboardFixture();
    final ranked = d.classRankings.single.ranked;
    await pumpSimulation(tester, row(d));

    expect(find.text('Écart entre classes'), findsOneWidget);
    expect(
      find.textContaining(
        'Sur frais de scolarité, de ${ranked.first.ratePercent} % '
        '(${ranked.first.classroomName}) à ${ranked.last.ratePercent} %',
      ),
      findsOneWidget,
    );
  });

  testWidgets('le classement suit le frais du bloc D, sinon le premier', (
    tester,
  ) async {
    final d = withSimulation(
      recoveryDashboardFixture(),
      rankings: [
        RecoveryClassRanking(
          feeCode: 'TUITION',
          currency: 'USD',
          ranked: [_class('a', 'A', 90), _class('b', 'B', 10)],
        ),
        RecoveryClassRanking(
          feeCode: 'SUPPLIES',
          currency: 'USD',
          ranked: [_class('c', 'C', 70), _class('d', 'D', 40)],
        ),
      ],
    );
    await pumpSimulation(tester, row(d, fee: 'SUPPLIES'));
    expect(find.textContaining('de 70 % (C) à 40 % (D)'), findsOneWidget);

    await pumpSimulation(tester, row(d, fee: 'UNKNOWN'));
    expect(find.textContaining('de 90 % (A) à 10 % (B)'), findsOneWidget);
  });

  testWidgets('un frais en deux devises : « code|devise » choisit la '
      'devise, comme le bloc D', (tester) async {
    final d = withSimulation(
      recoveryDashboardFixture(),
      rankings: [
        RecoveryClassRanking(
          feeCode: 'TUITION',
          currency: 'USD',
          ranked: [_class('a', 'A', 90), _class('b', 'B', 10)],
        ),
        RecoveryClassRanking(
          feeCode: 'TUITION',
          currency: 'CDF',
          ranked: [_class('c', 'C', 70), _class('d', 'D', 40)],
        ),
      ],
    );
    await pumpSimulation(tester, row(d, fee: 'TUITION|CDF'));
    expect(find.textContaining('de 70 % (C) à 40 % (D)'), findsOneWidget);

    await pumpSimulation(tester, row(d, fee: 'TUITION|USD'));
    expect(find.textContaining('de 90 % (A) à 10 % (B)'), findsOneWidget);

    // Le seul code d'un frais en deux devises : le premier choix qui convient.
    await pumpSimulation(tester, row(d, fee: 'TUITION'));
    expect(find.textContaining('de 90 % (A) à 10 % (B)'), findsOneWidget);
  });

  testWidgets('une seule classe : pas d\'écart (R13)', (tester) async {
    final d = withSimulation(
      recoveryDashboardFixture(),
      rankings: [
        RecoveryClassRanking(
          feeCode: 'TUITION',
          currency: 'USD',
          ranked: [_class('a', 'A', 90)],
        ),
      ],
    );
    await pumpSimulation(tester, row(d));
    expect(find.text('Écart entre classes'), findsNothing);
    expect(find.byType(RecoveryInsightCard), findsNWidgets(2));
  });

  testWidgets('ce que dit la simulation, selon le seuil', (tester) async {
    await pumpSimulation(tester, row(recoveryDashboardFixture()));
    expect(
      find.textContaining('Le renvoi ferait passer 7 classes sous 60 %'),
      findsOneWidget,
    );

    final calm = withSimulation(
      recoveryDashboardFixture(),
      simulation: simulationOf([
        simRow('c1', '1ère', headcount: 30, targeted: 3),
      ]),
    );
    await pumpSimulation(tester, row(calm));
    expect(
      find.textContaining(
        'Aucune classe ne descendrait sous 60 % : la mesure resterait '
        'tenable, avec 27 élèves sur 30 conservés.',
      ),
      findsOneWidget,
    );
  });

  Future<List<double>> tops(WidgetTester tester, double width) async {
    await pumpSimulation(tester, row(recoveryDashboardFixture()), width: width);
    return [
      for (final e in find.byType(RecoveryInsightCard).evaluate())
        tester.getTopLeft(find.byWidget(e.widget)).dy,
    ];
  }

  testWidgets('une colonne, puis 2 + 1, puis trois en ligne', (tester) async {
    var y = await tops(tester, 360);
    expect(y.toSet().length, 3);
    y = await tops(tester, 552);
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[0]));
    y = await tops(tester, 708);
    expect(y[0], y[1]);
    expect(y[2], greaterThan(y[0]));
    y = await tops(tester, 828);
    expect(y.toSet().length, 1);
  });

  for (final scale in [1.0, 1.3]) {
    for (final width in simulationWidths) {
      testWidgets('tient à $width dp, texte ×$scale', (tester) async {
        await pumpSimulation(
          tester,
          row(recoveryMixedDashboardFixture()),
          width: width,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
