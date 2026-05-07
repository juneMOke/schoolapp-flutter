import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_dropdown.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 420, child: child),
        ),
      ),
    );
  }

  testWidgets('fallback status maps to first dropdown value', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        SearchFormStatusDropdown(
          selectedStatus: 'UNKNOWN_STATUS',
          onChanged: (_) {},
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );

    expect(dropdown.initialValue, 'IN_PROGRESS');
  });

  testWidgets('uses medium badge for selected item and small badges in menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        SearchFormStatusDropdown(
          selectedStatus: 'VALIDATED',
          onChanged: (_) {},
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

    await tester.tap(find.byType(DropdownButtonFormField<String>));
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
