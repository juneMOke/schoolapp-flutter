import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
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

  testWidgets(
    'ligne brouillon (DRAFT) : badge « Brouillon » à côté du statut, sans '
    'débordement',
    (tester) async {
      const draft = EnrollmentSummary(
        enrollmentId: 'draft-1',
        enrollmentCode: '',
        status: 'IN_PROGRESS',
        student: StudentSummary(
          id: 'stu-9',
          firstName: 'Amina',
          lastName: 'Moke',
          surname: 'Junior',
          dateOfBirth: '2015-04-02',
          gender: Gender.female,
        ),
        syncState: SyncState.draft,
      );

      await tester.pumpWidget(
        buildHarness(
          SizedBox(
            width: 800,
            child: EnrollmentDataTable(
              enrollments: const <EnrollmentSummary>[draft],
              onViewRequested: (_) {},
            ),
          ),
        ),
      );

      // Aucune exception de layout (Row de badges bornés sous FittedBox).
      expect(tester.takeException(), isNull);
      // Statut métier conservé + badge « Brouillon ».
      expect(find.byType(EnrollmentStatusBadge), findsOneWidget);
      expect(find.text('Brouillon'), findsOneWidget);
    },
  );

  testWidgets(
    'ligne non-brouillon (syncState null) : aucun badge « Brouillon »',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          SizedBox(
            width: 800,
            child: EnrollmentDataTable(
              enrollments: const <EnrollmentSummary>[enrollment],
              onViewRequested: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Brouillon'), findsNothing);
    },
  );

  testWidgets('dossier RE avec brouillon local : pastille « En cours »', (
    tester,
  ) async {
    const reDraft = EnrollmentSummary(
      enrollmentId: 'enr-re-1',
      enrollmentCode: 'RE-001',
      status: 'PRE_REGISTERED',
      enrollmentType: 'RE_ENROLLMENT',
      syncState: SyncState.draft,
      student: StudentSummary(
        id: 'stu-10',
        firstName: 'Amina',
        lastName: 'Moke',
        surname: 'Junior',
        dateOfBirth: '2015-04-02',
        gender: Gender.female,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 800,
          child: EnrollmentDataTable(
            enrollments: const <EnrollmentSummary>[reDraft],
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Réinscrit'), findsNothing);
  });

  testWidgets('dossier RE finalisé/synchronisé : pastille « Réinscrit »', (
    tester,
  ) async {
    const reFinalized = EnrollmentSummary(
      enrollmentId: 'enr-re-2',
      enrollmentCode: 'RE-002',
      status: 'IN_PROGRESS',
      enrollmentType: 'RE_ENROLLMENT',
      syncState: SyncState.synced,
      student: StudentSummary(
        id: 'stu-11',
        firstName: 'Amina',
        lastName: 'Moke',
        surname: 'Junior',
        dateOfBirth: '2015-04-02',
        gender: Gender.female,
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 800,
          child: EnrollmentDataTable(
            enrollments: const <EnrollmentSummary>[reFinalized],
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Réinscrit'), findsOneWidget);
    expect(find.text('En cours'), findsNothing);
  });

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
