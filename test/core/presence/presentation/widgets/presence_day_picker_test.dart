import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que le calendrier du registre a rendu en se refermant.
class _Result {
  String? day;
  bool closed = false;
}

/// Le calendrier d'un registre : borné comme les flèches, jamais un
/// week-end, et un jour initial toujours choisissable.
void main() {
  Future<_Result> open(
    WidgetTester tester, {
    required String day,
    required String? firstDay,
    String lastDay = '2026-10-27',
  }) async {
    final result = _Result();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result.day = await pickPresenceDay(
                  context,
                  day: day,
                  firstDay: firstDay,
                  lastDay: lastDay,
                );
                result.closed = true;
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return result;
  }

  DatePickerDialog dialog(WidgetTester tester) =>
      tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));

  testWidgets('bornes : la rentrée → le dernier jour ouvré ; pas de week-end', (
    tester,
  ) async {
    await open(tester, day: '2026-10-20', firstDay: '2026-09-01');

    final picker = dialog(tester);
    expect(picker.firstDate, DateTime(2026, 9, 1));
    expect(picker.lastDate, DateTime(2026, 10, 27));
    expect(picker.initialDate, DateTime(2026, 10, 20));
    expect(picker.selectableDayPredicate!(DateTime(2026, 10, 24)), isFalse);
    expect(picker.selectableDayPredicate!(DateTime(2026, 10, 23)), isTrue);
  });

  testWidgets('rentrée inconnue : une année en arrière', (tester) async {
    await open(tester, day: '2026-10-20', firstDay: null);

    expect(dialog(tester).firstDate, DateTime(2025, 10, 27));
  });

  testWidgets('un jour hors bornes repart du dernier jour ouvré', (
    tester,
  ) async {
    await open(tester, day: '2026-08-14', firstDay: '2026-09-01');

    expect(dialog(tester).initialDate, DateTime(2026, 10, 27));
  });

  testWidgets('choisir rend le jour ; annuler rend null', (tester) async {
    final chosen = await open(tester, day: '2026-10-20', firstDay: null);
    Navigator.of(
      tester.element(find.byType(DatePickerDialog)),
    ).pop(DateTime(2026, 10, 2));
    await tester.pumpAndSettle();
    expect(chosen.day, '2026-10-02');

    final cancelled = await open(tester, day: '2026-10-20', firstDay: null);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
    await tester.pumpAndSettle();
    expect(cancelled.closed, isTrue);
    expect(cancelled.day, isNull);
  });
}
