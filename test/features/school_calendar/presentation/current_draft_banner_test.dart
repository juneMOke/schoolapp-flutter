import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/repositories/school_calendar_repository.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendar_card.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/calendars_list_view.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/current_year_hero.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import 'fake_calendar_repository.dart';

/// Une école arrivée en cours d'année : le seul calendrier, 2026-2027, est
/// un brouillon dont l'année a commencé (cas de staging du 2026-11-21).
class _DraftOnly extends FakeCalendarRepository {
  var status = CalendarStatus.draft;
  final List<SchoolCalendar> extra;

  _DraftOnly({this.extra = const []});

  SchoolCalendar get _current =>
      calendar('2026-2027', status, d(2026, 9, 1), d(2027, 7, 2));

  @override
  Future<CalendarLibrary> library() async =>
      CalendarLibrary(calendars: [_current, ...extra], frameworks: const []);

  @override
  Future<Either<Failure, SchoolCalendar>> publish(SchoolCalendar c) async {
    status = CalendarStatus.published;
    return Right(_current);
  }
}

Future<SchoolCalendarCubit> _load(FakeCalendarRepository repo) async {
  final c = SchoolCalendarCubit(
    repo,
    schoolToday: () => DateTime(2026, 11, 21),
  );
  await c.load();
  return c;
}

Widget _host(
  SchoolCalendarCubit cubit, {
  bool canSeeDrafts = true,
  bool canPublish = true,
  List<SchoolCalendar>? published,
}) => MaterialApp(
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
            canCreate: canPublish,
            canSeeDrafts: canSeeDrafts,
            canPublish: canPublish,
            onCreate: () {},
            onOpen: (_) {},
            onPublish: (c) => published?.add(c),
          ),
        ),
      ),
    ),
  ),
);

void _wide(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('le brouillon de l’année en cours (décision B)', () {
    test('il couvre aujourd’hui et rien n’est en vigueur', () async {
      final c = await _load(_DraftOnly());
      expect(c.state.inForce, isNull);
      expect(c.state.currentDraft?.yearLabel, '2026-2027');
      await c.close();
    });

    test('pas de brouillon courant quand une année est en vigueur', () async {
      final c = await _load(
        _DraftOnly(
          extra: [
            calendar(
              '2025-2026',
              CalendarStatus.published,
              d(2025, 9, 1),
              d(2026, 12, 31),
            ),
          ],
        ),
      );
      expect(c.state.inForce?.yearLabel, '2025-2026');
      expect(c.state.currentDraft, isNull);
      await c.close();
    });

    test('un brouillon d’une année à venir ne prend pas le bandeau', () async {
      // Le faux dépôt de base : 2026-2027 en brouillon, au 10 juin 2026.
      final c = SchoolCalendarCubit(
        FakeCalendarRepository(),
        schoolToday: () => DateTime(2026, 6, 10),
      );
      await c.load();
      expect(c.state.currentDraft, isNull);
      await c.close();
    });

    testWidgets('bandeau brouillon, carte retirée de « À venir », Publier', (
      tester,
    ) async {
      _wide(tester);
      final published = <SchoolCalendar>[];
      final c = await _load(_DraftOnly());
      await tester.pumpWidget(_host(c, published: published));
      final hero = tester.widget<CurrentYearHero>(find.byType(CurrentYearHero));
      expect(hero.phase, CalendarPhase.draft);
      expect(find.textContaining('Pas encore publié'), findsOneWidget);
      expect(find.byType(CalendarCard), findsNothing);
      expect(find.text('À VENIR'), findsNothing);
      await tester.tap(find.text('Publier'));
      expect(published.single.yearLabel, '2026-2027');
      await c.close();
    });

    testWidgets('sans droit de publier ou hors ligne : pas de « Publier »', (
      tester,
    ) async {
      _wide(tester);
      final c = await _load(_DraftOnly());
      await tester.pumpWidget(_host(c, canPublish: false));
      expect(find.byType(CurrentYearHero), findsOneWidget);
      expect(find.text('Publier'), findsNothing);
      await c.close();
    });

    testWidgets('qui ne voit pas les brouillons n’a pas de bandeau', (
      tester,
    ) async {
      _wide(tester);
      final c = await _load(_DraftOnly());
      await tester.pumpWidget(_host(c, canSeeDrafts: false, canPublish: false));
      expect(find.byType(CurrentYearHero), findsNothing);
      expect(find.textContaining('Pas encore publié'), findsNothing);
      await c.close();
    });

    test(
      'publier depuis la liste y reste ; le bandeau passe en vigueur',
      () async {
        final c = await _load(_DraftOnly());
        final result = await c.publish(source: c.state.currentDraft);
        expect(result.isRight(), isTrue);
        expect(c.state.openYear, isNull);
        expect(c.state.inForce?.yearLabel, '2026-2027');
        expect(c.state.currentDraft, isNull);
        await c.close();
      },
    );
  });
}
