// Captures des blocs F et G du tableau de bord du Recouvrement — HORS CI.
//
//   flutter test screenshot_test/recouvrement_simulation_shots_test.dart \
//     --dart-define=SHOTS_OUT=/chemin/de/sortie
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_insights_row.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_panel.dart';
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
              RecoverySimulationPanel(
                dashboard: d,
                rule: RecoveryRuleKind.somePayment,
                thresholdInCents: null,
                unmanageableBelow: 60,
                onUnmanageableChanged: (_) {},
                onChangeRule: () {},
                onClassTapped: (_) {},
              ),
              const SizedBox(height: AppDimensions.spacingM),
              RecoveryInsightsRow(
                dashboard: d,
                rankingFeeCode: 'TUITION',
                unmanageableBelow: 60,
                onControlStudents: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  for (final w in [360.0, 584.0, 700.0, 860.0, 1312.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('simulation $w x$scale', (tester) async {
        await shoot(
          tester,
          'simulation_${w.toInt()}_x$scale',
          Size(w, 2600),
          page(false),
          textScale: scale,
        );
      });
    }
  }
}
