import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le sélecteur a rendu en se refermant.
class _Result {
  String? month;
  bool closed = false;
}

/// Le sélecteur de mois d'un registre : les douze mois de l'année scolaire,
/// les mois à venir grisés, le mois choisi rendu tel quel.
void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  Future<_Result> open(
    WidgetTester tester, {
    String month = '2026-10',
    String? firstMonth = '2026-09',
    String lastMonth = '2026-10',
  }) async {
    final result = _Result();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.month = await pickPresenceMonth(
                context,
                month: month,
                firstMonth: firstMonth,
                lastMonth: lastMonth,
              );
              result.closed = true;
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return result;
  }

  test('douze mois depuis la rentrée ; rentrée inconnue, onze en arrière', () {
    final fromStart = presencePickerMonths(
      firstMonth: '2026-09',
      lastMonth: '2026-10',
    );
    expect(fromStart.first, '2026-09');
    expect(fromStart.last, '2027-08');
    expect(fromStart, hasLength(12));

    final unknown = presencePickerMonths(
      firstMonth: null,
      lastMonth: '2026-10',
    );
    expect(unknown.first, '2025-11');
    expect(unknown.last, '2026-10');
  });

  testWidgets('un mois passé se choisit et referme le sélecteur', (
    tester,
  ) async {
    final result = await open(tester);
    expect(find.text('Choisir un mois'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('septembre 2026'));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.month, '2026-09');
  });

  testWidgets('un mois à venir se voit mais ne se choisit pas', (tester) async {
    final result = await open(tester);

    await tester.tap(find.bySemanticsLabel('novembre 2026'));
    await tester.pumpAndSettle();

    expect(result.closed, isFalse);
    expect(find.text('Choisir un mois'), findsOneWidget);
  });

  testWidgets('la croix referme sans rien choisir', (tester) async {
    final result = await open(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.month, isNull);
  });

  testWidgets('la navigation de mois : le mois s\'ouvre avec onPick, '
      'et se lit seulement sans', (tester) async {
    var picked = 0;
    Widget nav({VoidCallback? onPick}) => host(
      PresenceMonthNav(
        month: '2026-10',
        isCurrent: true,
        onPrevious: () {},
        onNext: () {},
        onCurrent: () {},
        onPick: onPick,
      ),
    );

    await tester.pumpWidget(nav());
    expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);

    await tester.pumpWidget(nav(onPick: () => picked++));
    await tester.tap(find.text('octobre 2026'));
    expect(picked, 1);
    expect(
      tester.getSize(find.byTooltip('Choisir un mois')).height,
      greaterThanOrEqualTo(48),
    );
  });
}
