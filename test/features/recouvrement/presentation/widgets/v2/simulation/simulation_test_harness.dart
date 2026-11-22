import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les formats de référence (largeur reçue) et le texte ×1,3.
const simulationWidths = <double>[360, 600, 640, 800, 1280];

/// Rend [child] dans une colonne défilante de [width] dp reçus, au texte
/// [textScale], en français.
Future<void> pumpSimulation(
  WidgetTester tester,
  Widget child, {
  double width = 1280,
  double height = 2400,
  double textScale = 1,
}) async {
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
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// La même réponse avec une autre simulation (et d'autres classements).
RecoveryDashboard withSimulation(
  RecoveryDashboard d, {
  RecoverySimulation? simulation,
  List<RecoveryClassRanking>? rankings,
  List<RecoveryFeeRate>? feeRates,
  List<String>? currencies,
}) => RecoveryDashboard(
  situationAt: d.situationAt,
  academicYear: d.academicYear,
  pendingWrites: d.pendingWrites,
  perimeterLabel: d.perimeterLabel,
  fees: d.fees,
  currencies: currencies ?? d.currencies,
  atLeastAvailable: d.atLeastAvailable,
  studentCount: d.studentCount,
  keyFigures: d.keyFigures,
  situations: d.situations,
  feeRates: feeRates ?? d.feeRates,
  classRankings: rankings ?? d.classRankings,
  ruleCounts: d.ruleCounts,
  simulation: simulation ?? d.simulation,
);

RecoverySimulationRow simRow(
  String? id,
  String name, {
  required int headcount,
  required int targeted,
  List<Money> lost = const [],
  List<Money> abandoned = const [],
}) => RecoverySimulationRow(
  classroomId: id,
  classroomName: name,
  cycleName: id == null ? null : 'Primaire',
  headcount: headcount,
  billedStudents: headcount,
  targetedStudents: targeted,
  remainingHeadcount: headcount - targeted,
  lostCollected: lost,
  abandonedOutstanding: abandoned,
);

RecoverySimulation simulationOf(
  List<RecoverySimulationRow> rows, {
  List<Money> lost = const [],
  List<Money> abandoned = const [],
}) {
  final headcount = rows.fold<int>(0, (s, r) => s + r.headcount);
  final targeted = rows.fold<int>(0, (s, r) => s + r.targetedStudents);
  return RecoverySimulation(
    rows: rows,
    headcount: headcount,
    targetedStudents: targeted,
    remainingHeadcount: headcount - targeted,
    lostCollected: lost,
    abandonedOutstanding: abandoned,
  );
}
