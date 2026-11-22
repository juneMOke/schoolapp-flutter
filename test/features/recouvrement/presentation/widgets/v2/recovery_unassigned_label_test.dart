import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../fixtures/recovery_fixtures.dart';
import 'simulation/simulation_test_harness.dart';

/// « Non affectés » arrive du serveur en français : la page écrit le libellé
/// traduit dès que `classroomId` est nul, dans D comme dans F.
void main() {
  Future<void> pumpEn(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(1280, 2400),
            disableAnimations: true,
          ),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('D · la rubrique des non-affectés, en anglais', (tester) async {
    final d = recoveryDashboardFixture();
    await pumpEn(
      tester,
      RecoveryClassRankingPanel(
        dashboard: d,
        rankingFeeCode: 'TUITION',
        onRankingFeeChanged: (_) {},
        onClassTapped: (_) {},
      ),
    );
    expect(find.text('Not assigned'), findsOneWidget);
    expect(find.text('Non affectés'), findsNothing);
  });

  testWidgets('F · la ligne des non-affectés, en anglais', (tester) async {
    await pumpEn(
      tester,
      RecoverySimulationTable(
        rows: [
          simRow('c1', '1ère primaire', headcount: 30, targeted: 6),
          simRow(null, 'Non affectés', headcount: 6, targeted: 2),
        ],
        unmanageableBelow: 60,
        onClassTapped: (_) {},
      ),
    );
    expect(find.text('Not assigned'), findsOneWidget);
    expect(find.text('Non affectés'), findsNothing);
  });
}
