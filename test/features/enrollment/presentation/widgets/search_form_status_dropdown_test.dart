import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 420, child: child)),
      ),
    );
  }

  // Un statut que le filtre ne connaît pas se replie sur la première option —
  // désormais « Tous les statuts ». C'est le repli honnête : imposer à sa place
  // un statut arbitraire cacherait des dossiers sans que personne l'ait demandé.
  testWidgets('un statut inconnu se replie sur « Tous les statuts »', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        SearchForm(
          academicYearId: '2025',
          status: 'UNKNOWN_STATUS',
          isLoading: false,
          dispatch: (_) {},
          showStatusFilter: true,
          onStatusChanged: (_) {},
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );

    expect(dropdown.value, kEnrollmentStatusFilterAll);
  });

  testWidgets('uses medium badge for selected item and small badges in menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        SearchForm(
          academicYearId: '2025',
          status: 'VALIDATED',
          isLoading: false,
          dispatch: (_) {},
          showStatusFilter: true,
          onStatusChanged: (_) {},
        ),
      ),
    );

    final badgesBeforeOpen = tester.widgetList<StatusBadge>(
      find.byType(StatusBadge),
    );
    expect(
      badgesBeforeOpen.any((badge) => badge.size == StatusBadgeSize.medium),
      isTrue,
    );

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    final badgesAfterOpen = tester.widgetList<StatusBadge>(
      find.byType(StatusBadge),
    );
    expect(
      badgesAfterOpen.any((badge) => badge.size == StatusBadgeSize.small),
      isTrue,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
  });
}
