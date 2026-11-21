import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_periods.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

CalendarElement period(
  String id,
  PeriodRhythm rhythm,
  int order,
  int? sub,
  DateTime s,
  DateTime e,
) => CalendarElement(
  id: id,
  source: CalendarSource.national,
  nature: CalendarNature.period,
  title: id,
  startDate: s,
  endDate: e,
  rhythm: rhythm,
  periodOrder: order,
  subPeriodOrder: sub,
);

void main() {
  const sem = PeriodRhythm.semester;
  const tri = PeriodRhythm.trimester;
  final s1 = period(
    'Premier semestre',
    sem,
    1,
    null,
    d(2025, 9, 1),
    d(2026, 1, 30),
  );
  final p1 = period('1re période', sem, 1, 1, d(2025, 9, 1), d(2025, 11, 7));
  final p2 = period('2e période', sem, 1, 2, d(2025, 11, 10), d(2026, 1, 30));
  final t2 = period(
    'Deuxième trimestre',
    tri,
    2,
    null,
    d(2026, 1, 5),
    d(2026, 3, 27),
  );
  final exam = CalendarElement(
    id: 'exam',
    source: CalendarSource.national,
    nature: CalendarNature.exam,
    title: 'Examen',
    startDate: d(2025, 11, 12),
    endDate: d(2025, 11, 14),
  );

  group('CalendarPeriods.finest', () {
    test('un semestre qui a des sous-périodes s’efface derrière elles', () {
      expect(CalendarPeriods.finest([s1, p1, p2, exam]), [p1, p2, exam]);
    });

    test('une période sans sous-période reste', () {
      expect(CalendarPeriods.finest([t2, exam]), [t2, exam]);
      expect(CalendarPeriods.finest([s1, t2, p1]), [t2, p1]);
    });

    test('les sous-périodes partagent le couloir 0 : une seule bande de '
        'période par semaine', () {
      final weeks = MonthLayout.compute(
        year: 2025,
        month: 11,
        elements: CalendarPeriods.finest([s1, p1, p2, exam]),
        maxLanes: 4,
      );
      for (final week in weeks) {
        final periods = week.bands.where(
          (b) => b.element.nature == CalendarNature.period,
        );
        expect(periods.every((b) => b.lane == 0), isTrue);
        final cols = <int>{};
        for (final b in periods) {
          for (var c = b.startCol; c <= b.endCol; c++) {
            expect(cols.add(c), isTrue, reason: 'deux périodes le même jour');
          }
        }
      }
    });
  });

  testWidgets('libellés : « P2 · 1er semestre », repli sur l’intitulé, '
      'infobulle avec les dates', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final l10n = AppLocalizations.of(ctx)!;
    expect(CalendarLabels.title(l10n, p2), 'P2 · 1er semestre');
    expect(CalendarLabels.title(l10n, t2), 'Deuxième trimestre');
    expect(CalendarLabels.title(l10n, exam), 'Examen');
    expect(
      CalendarLabels.tooltip(ctx, p1),
      'P1 · 1er semestre · 1 sept. → 7 nov.',
    );
  });
}
