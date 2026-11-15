import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_format_buttons.dart';

import '../../treasury_fixtures.dart';

class _MockReports extends Mock implements TreasuryReportsRepository {}

void main() {
  late _MockReports reports;

  setUpAll(() => registerFallbackValue(CashReportFormat.pdf));
  setUp(() {
    reports = _MockReports();
    GetIt.instance.registerSingleton<TreasuryReportsRepository>(reports);
  });
  tearDown(() => GetIt.instance.unregister<TreasuryReportsRepository>());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    treasuryHost(
      const ReportFormatButtons(
        reportId: 'RJ-20261022',
        title: 'Jeudi 22 octobre 2026',
      ),
    ),
  );

  testWidgets('le PDF se demande par l id du rapport', (tester) async {
    when(
      () => reports.file(any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await pump(tester);
    await tester.tap(find.text('PDF'));
    await tester.pump();
    verify(() => reports.file('RJ-20261022', CashReportFormat.pdf)).called(1);
  });

  testWidgets('429 : la caissière sait qu un autre rapport se prépare', (
    tester,
  ) async {
    when(
      () => reports.file(any(), any()),
    ).thenAnswer((_) async => const Left(TooManyRequestsFailure()));
    await pump(tester);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(
      find.text('Un autre rapport se prépare : réessayez dans un instant.'),
      findsOneWidget,
    );
  });
}
