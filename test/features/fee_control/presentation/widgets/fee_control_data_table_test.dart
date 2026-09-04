import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/fee_control/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/fee_control_data_table.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

FeeControlRow row(
  String id, {
  required String lastName,
  int expected = 150000,
  int mirror = 0,
  int pending = 0,
}) => FeeControlRow(
  summary: EnrollmentSummary(
    enrollmentId: 'enr-$id',
    enrollmentCode: 'code-$id',
    status: 'COMPLETED',
    syncState: SyncState.synced,
    student: StudentSummary(
      id: id,
      firstName: 'Prénom$id',
      lastName: lastName,
      surname: 'Post$id',
      dateOfBirth: '2010-01-01',
      gender: Gender.male,
    ),
  ),
  aggregate: LocalFeeChargeAggregate.single(
    studentId: id,
    expectedInCents: expected,
    paidMirrorInCents: mirror,
    paidPendingInCents: pending,
    currency: 'USD',
  ),
);

Future<void> _pumpTable(
  WidgetTester tester,
  List<FeeControlRow> rows, {
  ValueChanged<FeeControlRow>? onViewRequested,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        child: FeeControlDataTable(
          rows: rows,
          totalCount: rows.length,
          onViewRequested: onViewRequested ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Montant tel que la table le rend (mêmes helpers que la production).
String _money(int cents) =>
    formatMonetaryAmountWithCurrency(amount: cents / 100, currency: 'USD');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rendu large : montants et pastille de statut', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [
      row('s1', lastName: 'MOKE', mirror: 90000),
      row('s2', lastName: 'KASONGO', mirror: 150000),
      row('s3', lastName: 'ILUNGA'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.byType(FeeStatusBadge), findsNWidgets(3));
    // Un statut par ligne, dérivé des montants (libellés partagés avec la
    // Facturation : « Payé » / « Partiel » / « À régler »).
    expect(find.text('Payé'), findsOneWidget);
    expect(find.text('Partiel'), findsOneWidget);
    expect(find.text('À régler'), findsOneWidget);
    // Colonnes montants présentes. Le montage passe par AppPageBackground, qui
    // borne son contenu à 1180 : ce test échoue si le seuil « large » repasse
    // au-dessus de ce plafond, auquel cas la disposition à 7 colonnes serait
    // inatteignable quelle que soit la taille de l'écran.
    expect(find.text('ATTENDU'), findsOneWidget);
    expect(find.text('PAYÉ'), findsOneWidget);
    expect(find.text('RESTE'), findsOneWidget);
  });

  testWidgets('le payé affiché inclut les encaissements pas encore remontés', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [
      row('s1', lastName: 'MOKE', mirror: 40000, pending: 110000),
    ]);

    // 40 000 + 110 000 = 150 000 → soldé, sans aucune synchronisation.
    expect(find.text('Payé'), findsOneWidget);
  });

  testWidgets('les montants portent la couleur de leur statut', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [
      row('s1', lastName: 'MOKE', expected: 150000, mirror: 90000),
    ]);

    Color? colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    // Payé > 0 → teinte « payé » ; reste > 0 → teinte « à régler ».
    expect(colorOf(_money(90000)), StudentChargeStatus.paid.badgeColor);
    expect(colorOf(_money(60000)), StudentChargeStatus.due.badgeColor);
    // L'attendu reste neutre : c'est la référence, pas un verdict.
    expect(colorOf(_money(150000)), isNot(StudentChargeStatus.due.badgeColor));
  });

  testWidgets('un zéro encaissé ne se teinte pas en « payé »', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [row('s1', lastName: 'MOKE', expected: 150000)]);

    final paidColor = tester.widget<Text>(find.text(_money(0))).style?.color;
    expect(paidColor, isNot(StudentChargeStatus.paid.badgeColor));
  });

  testWidgets('un frais soldé teinte le reste en « payé »', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [
      row('s1', lastName: 'MOKE', expected: 150000, mirror: 150000),
    ]);

    expect(
      tester.widget<Text>(find.text(_money(0))).style?.color,
      StudentChargeStatus.paid.badgeColor,
    );
  });

  testWidgets('rendu étroit : trois colonnes, statut conservé', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpTable(tester, [row('s1', lastName: 'MOKE', mirror: 90000)]);

    expect(tester.takeException(), isNull);
    expect(find.byType(FeeStatusBadge), findsOneWidget);
    expect(find.text('ATTENDU'), findsNothing);
    expect(find.text('RESTE'), findsOneWidget);
  });

  testWidgets('l\'œil remonte la ligne complète', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    FeeControlRow? tapped;
    await _pumpTable(tester, [
      row('s1', lastName: 'MOKE'),
    ], onViewRequested: (r) => tapped = r);

    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pumpAndSettle();

    expect(tapped?.summary.student.id, 's1');
  });
}
