import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/pending_sync_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, Locale locale) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: PendingSyncBadge())),
      ),
    );
  }

  testWidgets('dit « En attente de synchro » en français', (tester) async {
    await pumpBadge(tester, const Locale('fr'));

    expect(find.text('En attente de synchro'), findsOneWidget);
    expect(find.byIcon(Icons.sync_outlined), findsOneWidget);
  });

  testWidgets('dit « Pending sync » en anglais', (tester) async {
    await pumpBadge(tester, const Locale('en'));

    expect(find.text('Pending sync'), findsOneWidget);
  });
}
