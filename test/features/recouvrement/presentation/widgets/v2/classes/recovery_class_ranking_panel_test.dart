import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_ranking_options.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import '../figures/figures_test_harness.dart';

RecoveryDashboard _withRankings(
  RecoveryDashboard d,
  List<RecoveryClassRanking> rankings,
) => RecoveryDashboard(
  situationAt: d.situationAt,
  academicYear: d.academicYear,
  pendingWrites: d.pendingWrites,
  perimeterLabel: d.perimeterLabel,
  fees: d.fees,
  currencies: d.currencies,
  atLeastAvailable: d.atLeastAvailable,
  studentCount: d.studentCount,
  keyFigures: d.keyFigures,
  situations: d.situations,
  feeRates: d.feeRates,
  classRankings: rankings,
  ruleCounts: d.ruleCounts,
  simulation: d.simulation,
);

Future<List<RecoveryClassFeeRow>> _pump(
  WidgetTester tester,
  RecoveryDashboard dashboard, {
  double width = 1280,
  double textScale = 1,
  String fee = 'TUITION',
  ValueChanged<String>? onFee,
}) async {
  final tapped = <RecoveryClassFeeRow>[];
  await pumpFigures(
    tester,
    RecoveryClassRankingPanel(
      dashboard: dashboard,
      rankingFeeCode: fee,
      onRankingFeeChanged: onFee ?? (_) {},
      onClassTapped: tapped.add,
    ),
    width: width,
    height: 2400,
    textScale: textScale,
  );
  return tapped;
}

void main() {
  final dashboard = recoveryDashboardFixture();
  final ranking = dashboard.classRankings.single;

  testWidgets('titre, sous-titre et pastille du frais seul', (tester) async {
    await _pump(tester, dashboard);
    expect(find.text('Classes en tête et classes à relancer'), findsOneWidget);
    expect(
      find.text(
        'Sur un frais à la fois · touchez une classe pour voir ses élèves',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Frais de scolarité'), findsOneWidget);
    expect(find.byType(EteeloSelectInput<String>), findsNothing);
  });

  testWidgets('R7 : 4 en tête, 4 à relancer, le milieu absent ; '
      'Non affectés à part', (tester) async {
    await _pump(tester, dashboard);
    expect(find.text('EN TÊTE'), findsOneWidget);
    expect(find.text('À RELANCER EN PRIORITÉ'), findsOneWidget);
    for (final name in [
      '1ère maternelle',
      '2ème primaire',
      '1ère humanités',
      '3ème humanités',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('5ème primaire'), findsNothing);
    expect(find.text('Non affectés'), findsOneWidget);
    expect(find.text('NON AFFECTÉS · HORS CLASSEMENT'), findsOneWidget);
    // D7 : la ligne dit ses comptes, son taux et son reste.
    final first = ranking.ranked.first;
    expect(
      find.text(
        '${first.settledStudents}/${first.billedStudents} soldés · '
        '${first.noPaymentStudents} sans paiement',
      ),
      findsOneWidget,
    );
    expect(find.text('${first.ratePercent} %'), findsOneWidget);
  });

  testWidgets('toucher une classe ou Non affectés appelle onClassTapped', (
    tester,
  ) async {
    final tapped = await _pump(tester, dashboard);
    await tester.tap(find.text('3ème humanités'));
    await tester.tap(find.text('Non affectés'));
    expect(tapped.map((r) => r.classroomName), [
      '3ème humanités',
      'Non affectés',
    ]);
    expect(tapped.last.isUnassigned, isTrue);
  });

  testWidgets('une seule classe : « Une seule classe dans le périmètre. »', (
    tester,
  ) async {
    final one = _withRankings(dashboard, [
      RecoveryClassRanking(
        feeCode: 'TUITION',
        currency: 'USD',
        ranked: [ranking.ranked.first],
      ),
    ]);
    await _pump(tester, one);
    expect(find.text('1ère maternelle'), findsOneWidget);
    expect(find.text('Une seule classe dans le périmètre.'), findsOneWidget);
  });

  test('un frais en deux devises donne deux choix distincts', () {
    final two = _withRankings(dashboard, [
      ranking,
      RecoveryClassRanking(
        feeCode: 'TUITION',
        currency: 'CDF',
        ranked: ranking.ranked,
      ),
      RecoveryClassRanking(
        feeCode: 'SUPPLIES',
        currency: 'USD',
        ranked: ranking.ranked,
      ),
    ]);
    final options = RecoveryRankingOptions.of(two);
    expect(options.map((o) => o.value), [
      'TUITION|USD',
      'TUITION|CDF',
      'SUPPLIES',
    ]);
    expect(options.first.feeLabel, 'Frais de scolarité');
    expect(
      RecoveryRankingOptions.resolve(options, 'TUITION|CDF')!.currency,
      'CDF',
    );
    // Le seul code d'un frais en deux devises, ou un code inconnu.
    expect(RecoveryRankingOptions.resolve(options, 'TUITION')!.currency, 'USD');
    expect(RecoveryRankingOptions.resolve(options, 'NOPE'), options.first);
  });

  testWidgets('plusieurs frais : le choix, « libellé (symbole) »', (
    tester,
  ) async {
    final two = _withRankings(dashboard, [
      ranking,
      RecoveryClassRanking(
        feeCode: 'SUPPLIES',
        currency: 'USD',
        ranked: ranking.ranked.reversed.toList(),
      ),
    ]);
    await _pump(tester, two, fee: 'INCONNU');
    final select = tester.widget<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    );
    expect(select.value, 'TUITION');
    expect(select.items.map((i) => i.label), [
      r'Frais de scolarité ($)',
      r'Fournitures scolaires ($)',
    ]);
  });

  testWidgets('deux colonnes dès 760 reçus, l\'une sous l\'autre en deçà', (
    tester,
  ) async {
    await _pump(tester, dashboard, width: 800);
    expect(
      tester.getTopLeft(find.text('EN TÊTE')).dy,
      tester.getTopLeft(find.text('À RELANCER EN PRIORITÉ')).dy,
    );
    await _pump(tester, dashboard, width: 700);
    expect(
      tester.getTopLeft(find.text('À RELANCER EN PRIORITÉ')).dy,
      greaterThan(tester.getTopLeft(find.text('EN TÊTE')).dy),
    );
  });

  for (final width in [360.0, 600.0, 800.0, 1280.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$width dp, texte ×$scale : aucun débordement', (
        tester,
      ) async {
        await _pump(tester, dashboard, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        // Cibles ≥ 48 dp.
        expect(
          tester
              .getSize(find.bySemanticsLabel(RegExp('^Voir la classe')).first)
              .height,
          greaterThanOrEqualTo(48),
        );
      });
    }
  }
}
