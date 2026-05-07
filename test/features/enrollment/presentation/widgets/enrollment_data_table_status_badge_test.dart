import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
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

  testWidgets('EnrollmentDataTable renders EnrollmentStatusBadge in each row', (
    tester,
  ) async {
    final enrollment = EnrollmentSummary(
      enrollmentId: 'enr-1',
      enrollmentCode: 'ENR-001',
      status: 'VALIDATED',
      student: const StudentSummary(
        id: 'stu-1',
        firstName: 'Jean',
        lastName: 'Kanku',
        surname: 'Mbuyi',
        dateOfBirth: '2012-05-20',
        gender: Gender.male,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        EnrollmentDataTable(
          enrollments: [enrollment],
          onViewRequested: (_) {},
        ),
      ),
    );

    expect(find.byType(EnrollmentStatusBadge), findsOneWidget);
  });
}
