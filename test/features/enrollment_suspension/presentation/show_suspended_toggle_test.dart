import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/show_suspended_toggle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('la bascule annonce son compteur et se retourne', (tester) async {
    bool? next;
    await tester.pumpWidget(
      host(
        ShowSuspendedToggle(value: false, count: 3, onChanged: (v) => next = v),
      ),
    );

    expect(find.text('Afficher les désactivés'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(ShowSuspendedToggle));
    expect(next, isTrue);
  });

  testWidgets('le badge « Désactivé » est écrit, jamais une couleur seule', (
    tester,
  ) async {
    await tester.pumpWidget(host(StatusBadge.suspended(label: 'Désactivé')));
    expect(find.text('Désactivé'), findsOneWidget);
  });
}
