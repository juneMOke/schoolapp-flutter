import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('EnrollmentDetailInfoBar renders EnrollmentStatusBadge', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        const EnrollmentDetailInfoBar(
          studentDisplayName: 'Kanku Jean',
          status: EnrollmentStatus.validated,
          isPreviousYearValidated: true,
        ),
      ),
    );

    expect(find.byType(EnrollmentStatusBadge), findsOneWidget);
  });
}
