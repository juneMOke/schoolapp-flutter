import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../fixtures/recovery_fixtures.dart';

/// Ce que le panneau a fait remonter.
class PanelCalls {
  final rules = <RecoveryRuleKind>[];
  final thresholds = <int?>[];
  final tabs = <RecoveryTab>[];
  final searches = <String>[];
  final pages = <int>[];
  final students = <RecoveryStudentRow>[];
  var fees = 0;
  var retries = 0;
}

const tQuestion = RecoveryQuestion(feeCodes: ['TUITION']);
const tQuery = RecoveryStudentsQuery(question: tQuestion);

RecoveryStudentsState loaded(RecoveryStudentsPage page) =>
    RecoveryStudentsState(
      query: tQuery,
      status: RecoveryLoadStatus.success,
      page: page,
    );

/// Le panneau dans une page défilante de [width] dp, au texte [textScale].
Future<PanelCalls> pumpPanel(
  WidgetTester tester, {
  RecoveryDashboard? dashboard,
  RecoveryStudentsState? students,
  RecoveryRuleKind rule = RecoveryRuleKind.somePayment,
  int? threshold,
  RecoveryTab tab = RecoveryTab.toChase,
  String search = '',
  bool exportsEnabled = true,
  String? exportsDisabledReason,
  double width = 1280,
  double height = 2400,
  double textScale = 1,
  PanelCalls? calls,
}) async {
  final c = calls ?? PanelCalls();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RecoveryStudentsPanel(
              dashboard: dashboard ?? recoveryDashboardFixture(),
              students: students ?? loaded(recoveryStudentsFixture()),
              rule: rule,
              thresholdInCents: threshold,
              tab: tab,
              search: search,
              exportQuery: tQuery.copyWith(tab: tab),
              exportsEnabled: exportsEnabled,
              exportsDisabledReason: exportsDisabledReason,
              feesLabel: 'Scolarité',
              onRuleChanged: c.rules.add,
              onThresholdChanged: c.thresholds.add,
              onTabChanged: c.tabs.add,
              onSearchChanged: c.searches.add,
              onPageChanged: c.pages.add,
              onFeesTapped: () => c.fees++,
              onStudentTapped: c.students.add,
              onRetry: () => c.retries++,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return c;
}

/// La page de la fixture avec d'autres lignes ou compteurs.
RecoveryStudentsPage pageWith(
  RecoveryStudentsPage p, {
  List<RecoveryStudentRow>? content,
  List<String>? currencies,
  RecoveryTabCounts? counts,
  int? totalElements,
  int? totalPages,
}) => RecoveryStudentsPage(
  situationAt: p.situationAt,
  pendingWrites: p.pendingWrites,
  title: p.title,
  perimeterLabel: p.perimeterLabel,
  currencies: currencies ?? p.currencies,
  atLeastAvailable: p.atLeastAvailable,
  counts: counts ?? p.counts,
  situationCounts: p.situationCounts,
  content: content ?? p.content,
  page: p.page,
  size: p.size,
  totalElements: totalElements ?? p.totalElements,
  totalPages: totalPages ?? p.totalPages,
);

/// Un élève en deux devises, en ordre (il a payé des francs).
RecoveryStudentRow mixedRow() => const RecoveryStudentRow(
  studentId: 'mx',
  displayName: 'ILUNGA Tshibola Ruth',
  matriculationNumber: 'MAT-0900',
  classroomName: '3ème primaire',
  due: [Money(24000, 'USD'), Money(5000000, 'CDF')],
  paid: [Money(0, 'USD'), Money(2500000, 'CDF')],
  outstanding: [Money(24000, 'USD'), Money(2500000, 'CDF')],
  situation: StudentChargeStatus.partial,
  inOrder: true,
);
