import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendar_card.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_list_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/upcoming_appointments.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'fake_calendar_repository.dart';

/// La bibliothèque du faux dépôt, plus une archive 2023-2024.
class _WithArchive extends FakeCalendarRepository {
  @override
  Future<CalendarLibrary> library() async {
    final base = await super.library();
    return CalendarLibrary(
      calendars: [
        ...base.calendars,
        calendar(
          '2023-2024',
          CalendarStatus.published,
          d(2023, 9, 4),
          d(2024, 7, 5),
        ),
      ],
      frameworks: base.frameworks,
    );
  }
}

Widget _host(SchoolCalendarCubit cubit, {List<SchoolCalendar>? duplicated}) =>
    MaterialApp(
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
              child: CalendarsListView(
                state: state,
                canCreate: true,
                canDuplicate: true,
                onCreate: () {},
                onOpen: (_) {},
                onDuplicate: (c) => duplicated?.add(c),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  Future<SchoolCalendarCubit> load(FakeCalendarRepository repo) async {
    final c = SchoolCalendarCubit(
      repo,
      schoolToday: () => DateTime(2026, 6, 10),
    );
    await c.load();
    return c;
  }

  testWidgets('bandeau, rendez-vous et carte comptent les événements de '
      'l’école', (tester) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeCalendarRepository()
      ..extraItems = [
        CalendarElement(
          id: 'enafep',
          source: CalendarSource.national,
          nature: CalendarNature.exam,
          title: 'ENAFEP',
          startDate: d(2026, 6, 15),
          endDate: d(2026, 6, 17),
        ),
      ]
      ..stored = [
        SchoolEventRecord(
          element: item(
            'brouillon-1',
            CalendarNature.exam,
            national: false,
            toVerify: true,
          ),
          calendarId: 'cal-2026-2027',
          clientUpdatedAtMs: 1,
        ),
      ];
    final c = await load(repo);
    await tester.pumpWidget(_host(c));
    expect(find.byType(UpcomingAppointments), findsOneWidget);
    expect(find.text('Ouvrir le calendrier'), findsOneWidget);
    // La ligne des compteurs n'est plus dans le bandeau de la liste.
    expect(find.textContaining('internes'), findsNothing);
    expect(find.text('1 à vérifier'), findsOneWidget);
    expect(find.textContaining('1 élément interne'), findsOneWidget);
    await c.close();
  });

  testWidgets('les archives sont repliées, « Afficher » les déplie', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = await load(_WithArchive());
    await tester.pumpWidget(_host(c));
    expect(find.text('ARCHIVES'), findsOneWidget);
    expect(find.text('2023-2024'), findsNothing);
    await tester.tap(find.text('Afficher'));
    await tester.pump();
    expect(find.text('2023-2024'), findsOneWidget);
    expect(find.text('Masquer'), findsOneWidget);
    expect(find.byType(CalendarCard), findsNWidgets(2));
    await c.close();
  });

  testWidgets('le menu « ⋮ » duplique pour l’année suivante libre', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final duplicated = <SchoolCalendar>[];
    final c = await load(FakeCalendarRepository());
    await tester.pumpWidget(_host(c, duplicated: duplicated));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dupliquer pour 2027-2028'));
    await tester.pumpAndSettle();
    expect(duplicated.single.yearLabel, '2026-2027');
    // 2026-2027 existe déjà : pas d'astuce pour 2025-2026.
    expect(find.textContaining('Astuce'), findsNothing);
    await c.close();
  });
}
