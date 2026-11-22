// Captures des blocs B et C du tableau de bord du Recouvrement — HORS CI.
//
//   flutter test screenshot_test/recouvrement_figures_shots_test.dart \
//     --dart-define=SHOTS_OUT=/chemin/de/sortie
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_fee_rates_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_key_figures_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../test/features/recouvrement/fixtures/recovery_fixtures.dart';
import 'recouvrement_shots.dart';

void main() {
  setUpAll(loadRealFonts);

  Widget page(bool mixed) {
    final d = mixed
        ? recoveryMixedDashboardFixture()
        : recoveryDashboardFixture();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecoveryKeyFiguresSection(
                dashboard: d,
                onSituationTapped: (_) {},
              ),
              const SizedBox(height: AppDimensions.spacingM),
              RecoveryFeeRatesPanel(dashboard: d),
            ],
          ),
        ),
      ),
    );
  }

  for (final w in [360.0, 600.0, 860.0, 1312.0]) {
    for (final mixed in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('figures $w mixed=$mixed x$scale', (tester) async {
          await shoot(
            tester,
            'figures_${w.toInt()}_${mixed ? 'mixte' : 'usd'}_x$scale',
            Size(w, 1500),
            page(mixed),
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
