import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_fee_rates_panel.dart';

import '../../../../fixtures/recovery_fixtures.dart';
import 'figures_test_harness.dart';

/// Bloc C · taux par frais (spec §4.6 C, R6, D6, §7 `taux.*`).
void main() {
  testWidgets('un seul frais : synthèse de la devise et ligne du frais', (
    tester,
  ) async {
    await pumpFigures(
      tester,
      RecoveryFeeRatesPanel(dashboard: recoveryDashboardFixture()),
    );

    expect(find.text('Taux de recouvrement par frais'), findsOneWidget);
    expect(
      find.text('Un seul frais retenu · chaque devise se lit séparément'),
      findsOneWidget,
    );
    expect(find.textContaining('Frais en dollars'), findsOneWidget);
    expect(find.textContaining('Frais en francs'), findsNothing);
    final usd = money(13092000, 'USD');
    expect(
      find.text('${money(3612300, 'USD')} sur $usd · 28\u00a0% recouvrés'),
      findsOneWidget,
    );
    expect(find.text('Frais de scolarité'), findsOneWidget);
    expect(find.text('28\u00a0% de $usd'), findsOneWidget);
    expect(find.text('reste ${money(9479700, 'USD')}'), findsOneWidget);
  });

  testWidgets('mixte : dollars puis francs, sommes par devise seulement', (
    tester,
  ) async {
    await pumpFigures(
      tester,
      RecoveryFeeRatesPanel(dashboard: recoveryMixedDashboardFixture()),
    );

    expect(
      find.text('2 frais retenus · chaque devise se lit séparément'),
      findsOneWidget,
    );
    final dollars = find.textContaining('Frais en dollars');
    final francs = find.textContaining('Frais en francs');
    expect(dollars, findsOneWidget);
    expect(francs, findsOneWidget);
    expect(
      tester.getTopLeft(dollars).dy,
      lessThan(tester.getTopLeft(francs).dy),
    );
    expect(
      find.text(
        '${money(97500000, 'CDF')} sur ${money(221500000, 'CDF')} '
        '· 44\u00a0% recouvrés',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tous les frais retenus : « Les {n} frais » ; taux du groupe '
      '= (attendu − reste) / attendu', (tester) async {
    final base = recoveryDashboardFixture();
    final dashboard = withRates(base, [
      feeRate(
        'REGISTRATION',
        "Frais d'inscription",
        'CDF',
        due: 1000,
        paid: 500,
      ),
      feeRate('TUITION', 'Frais de scolarité', 'USD', due: 1000, paid: 100),
      // Payé en trop : le reste est planché, le taux suit le reste.
      feeRate(
        'SUPPLIES',
        'Fournitures scolaires',
        'USD',
        due: 1000,
        paid: 1200,
        outstanding: 0,
        rate: 100,
      ),
      feeRate('ACTIVITIES', 'Activités', 'USD', due: 0, paid: 0, billed: 0),
    ]);
    await pumpFigures(tester, RecoveryFeeRatesPanel(dashboard: dashboard));

    expect(
      find.text('Les 4 frais · chaque devise se lit séparément'),
      findsOneWidget,
    );
    // USD : attendu 2 000, reste 900 → 55 %.
    expect(
      find.text(
        '${money(1300, 'USD')} sur ${money(2000, 'USD')} · 55\u00a0% recouvrés',
      ),
      findsOneWidget,
    );
    // R1 : le frais facturé à personne n'a pas de taux.
    expect(find.text('Activités'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  for (final width in [328.0, 360.0, 600.0, 800.0, 1280.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('aucun débordement à $width dp, texte ×$scale', (
        tester,
      ) async {
        await pumpFigures(
          tester,
          RecoveryFeeRatesPanel(dashboard: recoveryMixedDashboardFixture()),
          width: width,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('sous 600 reçus, la ligne s’empile : le taux passe sous la '
      'barre', (tester) async {
    await pumpFigures(
      tester,
      RecoveryFeeRatesPanel(dashboard: recoveryDashboardFixture()),
      width: 360,
    );
    final label = tester.getTopLeft(find.text('Frais de scolarité'));
    final rate = tester.getTopLeft(
      find.text('28\u00a0% de ${money(13092000, 'USD')}'),
    );
    expect(rate.dy, greaterThan(label.dy));
  });
}
