import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_sale_time.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_tones.dart';

void main() {
  test('le tableau des ventes porte le ton des reçus de la caisse', () {
    expect(BoutiqueDashboardTones.ventes, DashboardSense.attente);
    final tone = BoutiqueDashboardTones.tableOf(BoutiqueDashboardTones.ventes);
    expect(tone.header, DashboardTones.entete(DashboardSense.attente));
    expect(tone.zebra, DashboardTones.zebrure(DashboardSense.attente));
  });

  test('les encres d\'en-tête se lisent sur les deux bandeaux', () {
    for (final accent in [
      BoutiqueDashboardTones.ventes,
      BoutiqueDashboardTones.eleves,
    ]) {
      final tone = BoutiqueDashboardTones.tableOf(accent);
      for (final ink in [tone.headerInk, tone.headerInkSorted]) {
        expect(
          DashboardTones.contraste(ink, tone.header),
          greaterThanOrEqualTo(DashboardTones.seuilTexte),
        );
      }
    }
  });

  group('BoutiqueSaleTime', () {
    // Mercredi 21 octobre 2026, 14 h 30 à Kinshasa.
    final now = DateTime.utc(2026, 10, 21, 13, 30);

    test('aujourd\'hui : l\'heure seule, à l\'heure de l\'école', () {
      expect(BoutiqueSaleTime.of('2026-10-21T08:05:00Z', now), '09:05');
    });

    test('un autre jour : la date avec l\'heure, lue à Kinshasa', () {
      // 23 h 30 UTC le 29 = 0 h 30 le 30 à Kinshasa.
      expect(BoutiqueSaleTime.of('2026-08-29T23:30:00Z', now), '30/08 00:30');
    });

    test('un horodatage illisible reste affiché tel quel', () {
      expect(BoutiqueSaleTime.of('hier', now), 'hier');
    });
  });
}
