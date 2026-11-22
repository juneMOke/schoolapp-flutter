// Captures du bloc E « Où en est chaque élève ? » — HORS CI.
//
//   flutter test screenshot_test/recouvrement_students_shots_test.dart \
//     --dart-define=SHOTS_OUT=/chemin/de/sortie
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../test/features/recouvrement/fixtures/recovery_fixtures.dart';
import '../test/features/recouvrement/presentation/widgets/v2/students/students_test_harness.dart';
import 'recouvrement_shots.dart';

void main() {
  setUpAll(loadRealFonts);

  Widget page({
    required RecoveryDashboard dashboard,
    required RecoveryStudentsState students,
    RecoveryRuleKind rule = RecoveryRuleKind.somePayment,
    int? threshold,
    RecoveryTab tab = RecoveryTab.toChase,
  }) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: RecoveryStudentsPanel(
          dashboard: dashboard,
          students: students,
          rule: rule,
          thresholdInCents: threshold,
          tab: tab,
          search: '',
          exportQuery: tQuery.copyWith(tab: tab),
          exportsEnabled: true,
          feesLabel: 'Scolarité',
          onRuleChanged: (_) {},
          onThresholdChanged: (_) {},
          onTabChanged: (_) {},
          onSearchChanged: (_) {},
          onPageChanged: (_) {},
          onFeesTapped: () {},
          onStudentTapped: (_) {},
          onRetry: () {},
        ),
      ),
    ),
  );

  final mixedPage = pageWith(
    recoveryStudentsFixture(),
    currencies: ['CDF', 'USD'],
    content: [mixedRow(), ...recoveryStudentsFixture().content.take(4)],
  );

  for (final w in [360.0, 700.0, 1312.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('élèves $w x$scale', (tester) async {
        await shoot(
          tester,
          'students_${w.toInt()}_x$scale',
          Size(w, 2200),
          page(
            dashboard: recoveryDashboardFixture(),
            students: loaded(recoveryStudentsFixture()),
          ),
          textScale: scale,
        );
      });
    }
    testWidgets('élèves $w au moins 150', (tester) async {
      await shoot(
        tester,
        'students_${w.toInt()}_atleast',
        Size(w, 2200),
        page(
          dashboard: recoveryDashboardFixture(),
          students: loaded(recoveryStudentsFixture()),
          rule: RecoveryRuleKind.atLeast,
          threshold: 15000,
          tab: RecoveryTab.inOrder,
        ),
      );
    });
    testWidgets('élèves $w mixte', (tester) async {
      await shoot(
        tester,
        'students_${w.toInt()}_mixte',
        Size(w, 2000),
        page(
          dashboard: recoveryMixedDashboardFixture(),
          students: loaded(mixedPage),
          tab: RecoveryTab.all,
        ),
      );
    });
  }
}
