import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_rights.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar/calendar_detail_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_list_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import 'fake_calendar_repository.dart';

Widget _host(
  SchoolCalendarCubit cubit,
  Widget Function(SchoolCalendarState) body,
) => MaterialApp(
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
          padding: const EdgeInsets.all(16),
          child: body(state),
        ),
      ),
    ),
  ),
);

const _rights = CalendarRights(
  writableNatures: {
    CalendarNature.assessment,
    CalendarNature.exam,
    CalendarNature.holidayBreak,
    CalendarNature.schoolLife,
  },
  canPublish: true,
);

void main() {
  Future<SchoolCalendarCubit> cubit() async {
    final c = SchoolCalendarCubit(
      FakeCalendarRepository(),
      schoolToday: () => DateTime(2026, 6, 10),
    );
    await c.load();
    return c;
  }

  testAtReferenceFormats('liste des calendriers', (tester, format) async {
    final c = await cubit();
    await tester.pumpWidget(
      _host(
        c,
        (state) => CalendarsListView(
          state: state,
          canCreate: true,
          onCreate: () {},
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('2025-2026'), findsWidgets);
    await c.close();
  });

  for (final view in CalendarView.values) {
    testAtReferenceFormats('un calendrier, vue ${view.name}', (
      tester,
      format,
    ) async {
      final c = await cubit();
      await c.open('2025-2026');
      c.setView(view);
      await tester.pumpWidget(
        _host(
          c,
          (state) => CalendarDetailView(
            state: state,
            cubit: c,
            calendar: state.calendar!,
            rights: _rights,
            online: format.size.width > 700,
            actions: CalendarActions(
              back: () {},
              openElement: (_) {},
              addOn: (_) {},
              publish: () {},
              duplicate: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CalendarDetailView), findsOneWidget);
      await c.close();
    });
  }
}
