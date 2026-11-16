import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/cash_report_viewer.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';
import '../../xlsx_fixture.dart';

class _MockReports extends Mock implements TreasuryReportsRepository {}

CashReportFile _file(CashReportFormat format, {bool provisional = false}) =>
    CashReportFile(
      bytes: format == CashReportFormat.xlsx
          ? cashReportXlsx()
          : Uint8List.fromList([37, 80, 68, 70]),
      fileName: 'RJ-20261022.${format.name}',
      format: format,
      status: provisional
          ? CashReportStatus.provisional
          : CashReportStatus.finalReport,
    );

void main() {
  late _MockReports reports;

  setUpAll(() => registerFallbackValue(CashReportFormat.pdf));

  setUp(() {
    reports = _MockReports();
    when(
      () => reports.file(any(), any()),
    ).thenAnswer((i) async => Right(_file(i.positionalArguments[1])));
  });

  Future<void> pump(WidgetTester tester, CashReportFormat initial) async {
    await tester.pumpWidget(
      treasuryHost(
        SizedBox(
          height: 900,
          child: CashReportViewer(
            reportId: 'RJ-20261022',
            title: 'Jeudi 22 octobre 2026',
            initialFormat: initial,
            repository: reports,
            pdfPreviewBuilder: (_) => const Text('page PDF'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Excel : l aperçu de la feuille, onglet par onglet', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1000));
    await pump(tester, CashReportFormat.xlsx);
    expect(find.text('Total encaissé'), findsOneWidget);
    expect(find.text('3 450 000 FC'), findsOneWidget);
    expect(find.text('Enregistrer la feuille'), findsOneWidget);
    await tester.tap(find.text('Données'));
    await tester.pumpAndSettle();
    expect(find.text('22/10/2026'), findsOneWidget);
  });

  testWidgets('la bascule PDF | Excel demande l autre fichier une fois', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1000));
    await pump(tester, CashReportFormat.pdf);
    expect(find.text('page PDF'), findsOneWidget);
    expect(find.text('Imprimer'), findsOneWidget);
    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    expect(find.text('Total encaissé'), findsOneWidget);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel'));
    await tester.pumpAndSettle();
    verify(() => reports.file('RJ-20261022', CashReportFormat.xlsx)).called(1);
    verify(() => reports.file('RJ-20261022', CashReportFormat.pdf)).called(1);
  });

  testWidgets('un rapport provisoire le dit au-dessus du document', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 1000));
    when(() => reports.file(any(), any())).thenAnswer(
      (i) async => Right(_file(i.positionalArguments[1], provisional: true)),
    );
    await pump(tester, CashReportFormat.pdf);
    expect(find.textContaining('Rapport provisoire'), findsOneWidget);
    expect(find.text('RJ-20261022 · provisoire'), findsOneWidget);
  });

  testWidgets('un échec : l état d erreur et « Réessayer »', (tester) async {
    setTestWindow(tester, const Size(1280, 1000));
    when(
      () => reports.file(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await pump(tester, CashReportFormat.xlsx);
    expect(find.text('Réessayer'), findsOneWidget);
    when(
      () => reports.file(any(), any()),
    ).thenAnswer((i) async => Right(_file(i.positionalArguments[1])));
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Total encaissé'), findsOneWidget);
  });

  testAtReferenceFormats('la visionneuse tient sur tous les formats', (
    tester,
    _,
  ) async {
    await tester.pumpWidget(
      treasuryHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showEteeloAdaptiveDialog<void>(
              context: context,
              builder: (_) => CashReportViewer(
                reportId: 'RJ-20261022',
                title: 'Jeudi 22 octobre 2026',
                initialFormat: CashReportFormat.xlsx,
                repository: reports,
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    // Les onglets restent visibles ; la grille ne bâtit que ses lignes à
    // l'écran (téléphone paysage : quelques-unes).
    expect(find.text('Données'), findsOneWidget);
  });
}
