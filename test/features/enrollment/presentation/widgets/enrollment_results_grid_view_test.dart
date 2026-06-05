import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/grid/eteelo_grid_view.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_result_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_grid_view.dart';
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

  EnrollmentSummary createMockEnrollment(int index) {
    return EnrollmentSummary(
      enrollmentId: 'enrollment-$index',
      enrollmentCode: 'ENC-$index',
      status: 'DRAFT',
      student: StudentSummary(
        id: 'student-$index',
        firstName: 'Student',
        lastName: 'Number$index',
        surname: 'Num$index',
        dateOfBirth: '2010-01-15',
        gender: Gender.male,
      ),
    );
  }

  testWidgets('Grid view displays items in grid layout', (tester) async {
    final items = [
      createMockEnrollment(1),
      createMockEnrollment(2),
      createMockEnrollment(3),
    ];

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 400,
          height: 800,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    // Should render grid items (GridView only renders visible items)
    expect(find.byType(EteeloGridView), findsOneWidget);
    expect(find.byType(EnrollmentResultCard), findsWidgets);
  });

  testWidgets('Grid view ajuste la hauteur de carte à son contenu (fit)', (
    tester,
  ) async {
    final items = [createMockEnrollment(1)];

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 500,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    // Plus de tuile à hauteur uniforme : rendu Wrap, pas de GridView.
    expect(find.byType(GridView), findsNothing);
    // La carte épouse son contenu (pas de grand vide en bas).
    final cardHeight = tester.getSize(find.byType(EnrollmentResultCard)).height;
    expect(cardHeight, lessThan(200));
  });

  testWidgets('Grid view supports item selection', (tester) async {
    var tappedId = '';

    final items = [createMockEnrollment(1), createMockEnrollment(2)];

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 500,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (enrollment) => tappedId = enrollment.enrollmentId,
          ),
        ),
      ),
    );

    // Tap first card
    await tester.tap(find.byType(EnrollmentResultCard).first);
    await tester.pump();

    expect(tappedId, 'enrollment-1');
  });

  testWidgets('Grid view handles empty state', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 400,
          child: EnrollmentResultsGridView(
            enrollments: const [],
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    // No cards should be rendered
    expect(find.byType(EnrollmentResultCard), findsNothing);
  });

  testWidgets('Grid view passe en une seule colonne sous 360px', (
    tester,
  ) async {
    final items = List.generate(2, (i) => createMockEnrollment(i));

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 350,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    final firstTopLeft = tester.getTopLeft(
      find.byType(EnrollmentResultCard).at(0),
    );
    final secondTopLeft = tester.getTopLeft(
      find.byType(EnrollmentResultCard).at(1),
    );

    expect(secondTopLeft.dx, firstTopLeft.dx);
    expect(secondTopLeft.dy, greaterThan(firstTopLeft.dy));
  });
}
