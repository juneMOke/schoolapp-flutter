import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_notice_stack.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<String> texts, {
    List<String> alerts = const [],
  }) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PayrollNoticeStack(
          alerts: [for (final text in alerts) Text(text)],
          infos: [for (final text in texts) Text(text)],
        ),
      ),
    ),
  );

  testWidgets('la première information reste visible, les autres se replient', (
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

  testWidgets('une alerte ne se replie jamais', (tester) async {
    await pump(
      tester,
      ['Lignes figées attendues', 'Arriérés'],
      alerts: ['Versement à régulariser', 'Refus PAYROLL_STALE'],
    );

    expect(find.text('Versement à régulariser'), findsOneWidget);
    expect(find.text('Refus PAYROLL_STALE'), findsOneWidget);
    expect(find.text('Lignes figées attendues'), findsOneWidget);
    expect(find.text('Arriérés'), findsNothing);
    expect(find.text('1 autre point'), findsOneWidget);
  });
}
