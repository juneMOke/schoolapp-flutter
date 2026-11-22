import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rend [child] dans une colonne défilante de [width] dp reçus, au texte
/// [textScale], en français.
Future<void> pumpFigures(
  WidgetTester tester,
  Widget child, {
  double width = 1280,
  double height = 1400,
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

String money(int cents, String currency) =>
    MoneyFormat.compact(Money(cents, currency));

/// La même réponse avec d'autres lignes de taux (et de frais).
RecoveryDashboard withRates(
  RecoveryDashboard d,
  List<RecoveryFeeRate> rates, {
  List<RecoveryFee>? fees,
}) => RecoveryDashboard(
  situationAt: d.situationAt,
  academicYear: d.academicYear,
  pendingWrites: d.pendingWrites,
  perimeterLabel: d.perimeterLabel,
  fees: fees ?? d.fees,
  currencies: d.currencies,
  atLeastAvailable: d.atLeastAvailable,
  studentCount: d.studentCount,
  keyFigures: d.keyFigures,
  situations: d.situations,
  feeRates: rates,
  classRankings: d.classRankings,
  ruleCounts: d.ruleCounts,
  simulation: d.simulation,
);

RecoveryFeeRate feeRate(
  String code,
  String label,
  String currency, {
  required int due,
  required int paid,
  int? outstanding,
  int billed = 10,
  int? rate,
}) => RecoveryFeeRate(
  feeCode: code,
  label: label,
  billedStudents: billed,
  figures: RecoveryFigures(
    currency: currency,
    dueInCents: due,
    paidInCents: paid,
    outstandingInCents: outstanding ?? (due - paid),
    ratePercent: rate ?? (due == 0 ? null : (paid * 100 / due).round()),
  ),
);
