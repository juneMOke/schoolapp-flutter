import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildResponsiveHarness({
    required double width,
    required Widget child,
  }) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('Results bar displays count on mobile (390px)', (tester) async {
    await tester.pumpWidget(
      buildResponsiveHarness(
        width: 390,
        child: const EnrollmentResultsBar(
          count: 42,
          isLoading: false,
          currentViewMode: EnrollmentListingViewMode.auto,
        ),
      ),
    );

    // Counter should display on mobile
    expect(find.text('42 résultats'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_turned_in_outlined), findsOneWidget);
  });

  testWidgets('Results bar displays on tablet (820px)', (tester) async {
    await tester.pumpWidget(
      buildResponsiveHarness(
        width: 820,
        child: const EnrollmentResultsBar(
          count: 42,
          isLoading: false,
          currentViewMode: EnrollmentListingViewMode.auto,
        ),
      ),
    );

    expect(find.text('42 résultats'), findsOneWidget);
  });

  testWidgets('Alternative count format singular', (tester) async {
    await tester.pumpWidget(
      buildResponsiveHarness(
        width: 500,
        child: const EnrollmentResultsBar(
          count: 1,
          isLoading: false,
          currentViewMode: EnrollmentListingViewMode.auto,
        ),
      ),
    );

    expect(find.text('1 résultat'), findsOneWidget);
  });

  testWidgets('Breakpoint constants are correctly defined', (tester) async {
    // Verify the constants exist
    expect(AppBreakpoints.enrollmentTableGridSwitchMax, 600.0);
    expect(AppBreakpoints.enrollmentShellCompactMax, 1024.0);
  });

  testWidgets('Results bar shows loading state', (tester) async {
    await tester.pumpWidget(
      buildResponsiveHarness(
        width: 600,
        child: const EnrollmentResultsBar(
          count: 0,
          isLoading: true,
          currentViewMode: EnrollmentListingViewMode.auto,
        ),
      ),
    );

    // Loading should display loading message
    expect(find.text('Chargement des étudiants...'), findsOneWidget);
  });

  testWidgets('Results bar shows structured sort when options are provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildResponsiveHarness(
        width: 800,
        child: EnrollmentResultsBar(
          count: 10,
          isLoading: false,
          currentViewMode: EnrollmentListingViewMode.table,
          sortOptions: const [
            EnrollmentResultsSortOption(value: 'name_asc', label: 'Nom A-Z'),
          ],
          selectedSort: 'name_asc',
          onSortChanged: (_) {},
          onViewModeChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Trier'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });
}
