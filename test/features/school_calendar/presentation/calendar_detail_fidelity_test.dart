import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_detail_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_legend_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'fake_calendar_repository.dart';

const _rights = CalendarRights(
  writableNatures: {CalendarNature.schoolLife},
  canPublish: true,
);

Widget _host(SchoolCalendarCubit cubit) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: BlocProvider.value(
      value: cubit,
      child: BlocBuilder<SchoolCalendarCubit, SchoolCalendarState>(
        builder: (context, state) => SingleChildScrollView(
          child: CalendarDetailView(
            state: state,
            cubit: cubit,
            calendar: state.calendar!,
            rights: _rights,
            online: true,
            actions: CalendarActions(
              openElement: (_) {},
              addOn: (_) {},
              back: () {},
              publish: () {},
            ),
          ),
        ),
      ),
    ),
  ),
);

/// L'état passe par le flux du cubit, puis par une image : deux pompes.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  Future<SchoolCalendarCubit> open(WidgetTester tester, String year) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = SchoolCalendarCubit(
      FakeCalendarRepository(),
      schoolToday: () => DateTime(2026, 6, 10),
    );
    await c.load();
    await c.open(year);
    await tester.pumpWidget(_host(c));
    await tester.pump();
    return c;
  }

  testWidgets('le bandeau : titre « Calendrier … », semaines, aucun surtitre', (
    tester,
  ) async {
    final c = await open(tester, '2025-2026');
    expect(find.text('Calendrier 2025-2026'), findsOneWidget);
    expect(find.textContaining('44 semaines'), findsOneWidget);
    expect(find.text('Agenda & Horaires · Calendrier scolaire'), findsNothing);
    expect(find.text('En ce moment'), findsNothing);
    await c.close();
  });

  testWidgets('un brouillon hors de l’année : semaines, pas de « Mois en '
      'cours », flèche gauche inactive au premier mois', (tester) async {
    final c = await open(tester, '2026-2027');
    expect(find.textContaining('semaines'), findsOneWidget);
    expect(find.text('Mois en cours'), findsNothing);
    final previous = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_left_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(previous.onPressed, isNull);
    await c.close();
  });

  testWidgets('« Mois en cours » revient quand on s’éloigne du mois du jour', (
    tester,
  ) async {
    final c = await open(tester, '2025-2026');
    expect(find.text('Mois en cours'), findsNothing);
    c.shiftMonth(-1);
    await _settle(tester);
    expect(find.text('Mois en cours'), findsOneWidget);
    await c.close();
  });

  testWidgets('les compteurs de la légende suivent la source (I9)', (
    tester,
  ) async {
    final c = await open(tester, '2025-2026');
    int count(CalendarNature n) => tester
        .widget<CalendarLegendChip>(
          find.byWidgetPredicate(
            (w) => w is CalendarLegendChip && w.nature == n,
          ),
        )
        .count;
    expect(count(CalendarNature.schoolLife), 1);
    c.setSource(CalendarSourceFilter.national);
    await _settle(tester);
    expect(count(CalendarNature.schoolLife), 0);
    expect(count(CalendarNature.publicHoliday), 1);
    await c.close();
  });

  testWidgets('la vue Liste montre les périodes, et « Les passer en revue » '
      'devient « Tout afficher »', (tester) async {
    final c = await open(tester, '2025-2026');
    c.setView(CalendarView.list);
    await _settle(tester);
    expect(find.text('p-s'), findsWidgets);
    await tester.tap(find.text('Les passer en revue'));
    await _settle(tester);
    expect(c.state.verifyOnly, isTrue);
    expect(find.text('Tout afficher'), findsOneWidget);
    await c.close();
  });

  testWidgets('la liste du mois porte son compteur et les périodes', (
    tester,
  ) async {
    final c = await open(tester, '2025-2026');
    // p-s (période), ferie, reunion : trois éléments en juin.
    expect(find.text('p-s'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    await c.close();
  });
}
