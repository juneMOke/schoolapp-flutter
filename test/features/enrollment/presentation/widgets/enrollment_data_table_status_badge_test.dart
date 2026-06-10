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
    const enrollment = EnrollmentSummary(
      enrollmentId: 'enr-1',
      enrollmentCode: 'ENR-001',
      status: 'VALIDATED',
      student: StudentSummary(
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
          enrollments: const <EnrollmentSummary>[enrollment],
          onViewRequested: (_) {},
        ),
      ),
    );

    expect(find.byType(EnrollmentStatusBadge), findsOneWidget);
  });

  const enrollment = EnrollmentSummary(
    enrollmentId: 'enr-1',
    enrollmentCode: 'ENR-001',
    status: 'VALIDATED',
    student: StudentSummary(
      id: 'stu-1',
      firstName: 'Jean',
      lastName: 'Kanku',
      surname: 'Mbuyi',
      dateOfBirth: '2012-05-20',
      gender: Gender.male,
    ),
  );

  testWidgets('Téléphone (<600px) : 2 colonnes, date en sous-texte du nom', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      buildHarness(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return SizedBox(
              width: 360,
              child: EnrollmentDataTable(
                enrollments: const <EnrollmentSummary>[enrollment],
                onViewRequested: (_) {},
              ),
            );
          },
        ),
      ),
    );

    // La colonne Date disparaît de l'en-tête...
    expect(find.text(l10n.dateOfBirth.toUpperCase()), findsNothing);
    // ...mais l'en-tête Élève reste.
    expect(
      find.text(l10n.enrollmentStudentColumnLabel.toUpperCase()),
      findsOneWidget,
    );
    // ...et la date réapparaît en sous-texte de la ligne.
    expect(find.text('20/05/2012'), findsOneWidget);
  });

  testWidgets('Large écran (>=600px) : 3 colonnes dont la colonne Date', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      buildHarness(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return SizedBox(
              width: 800,
              child: EnrollmentDataTable(
                enrollments: const <EnrollmentSummary>[enrollment],
                onViewRequested: (_) {},
              ),
            );
          },
        ),
      ),
    );

    expect(find.text(l10n.dateOfBirth.toUpperCase()), findsOneWidget);
    expect(find.text('20/05/2012'), findsOneWidget);
  });
}
