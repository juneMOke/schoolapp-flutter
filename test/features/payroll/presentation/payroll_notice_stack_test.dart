import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_notice_stack.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<String> texts) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PayrollNoticeStack(
              notices: [for (final text in texts) Text(text)],
            ),
          ),
        ),
      );

  testWidgets('le plus grave reste visible, les autres se replient', (
    tester,
  ) async {
    await pump(tester, ['Versement refusé', 'Pointage ouvert', 'Arriérés']);

    expect(find.text('Versement refusé'), findsOneWidget);
    expect(find.text('Pointage ouvert'), findsNothing);
    expect(find.text('2 autres points'), findsOneWidget);

    await tester.tap(find.text('2 autres points'));
    await tester.pumpAndSettle();
    expect(find.text('Pointage ouvert'), findsOneWidget);
    expect(find.text('Arriérés'), findsOneWidget);

    await tester.tap(find.text('Masquer'));
    await tester.pumpAndSettle();
    expect(find.text('Arriérés'), findsNothing);
  });

  testWidgets('un seul bandeau : pas de repli', (tester) async {
    await pump(tester, ['Seul']);

    expect(find.text('Seul'), findsOneWidget);
    expect(find.text('Masquer'), findsNothing);
  });

  testWidgets('aucun bandeau : rien', (tester) async {
    await pump(tester, []);

    expect(find.byType(Text), findsNothing);
  });
}
