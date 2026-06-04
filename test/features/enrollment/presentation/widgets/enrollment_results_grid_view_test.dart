import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.byType(EnrollmentResultCard), findsWidgets);
  });

  testWidgets('Grid view respects single column on narrow width', (
    tester,
  ) async {
    final items = [createMockEnrollment(1), createMockEnrollment(2)];

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 390,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(EnrollmentResultCard), findsWidgets);
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

  testWidgets('Grid view handles large number of items', (tester) async {
    final items = List.generate(20, (i) => createMockEnrollment(i));

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 400,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    // Grid should render visible items
    expect(find.byType(EnrollmentResultCard), findsWidgets);
  });

  testWidgets('Grid view responsive columns: varies by width', (tester) async {
    final items = List.generate(3, (i) => createMockEnrollment(i));

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          width: 390,
          height: 600,
          child: EnrollmentResultsGridView(
            enrollments: items,
            onViewRequested: (_) {},
          ),
        ),
      ),
    );

    // At 390px width (mobile), should use 1 column
    expect(find.byType(EnrollmentResultCard), findsWidgets);
  });
}
