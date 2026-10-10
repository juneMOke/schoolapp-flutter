import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_day_sources.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_line.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_calendar.dart';
import 'package:school_app_flutter/features/class_journal/domain/services/journal_day_composer.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_day_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/cards/journal_card_list.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/journal_view.dart';
import 'package:school_app_flutter/features/class_journal/presentation/widgets/sheet/journal_sheet.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

import '../../../course_programme/presentation/programme_test_host.dart';
import '../../journal_fixtures.dart';

class _MockCubit extends MockCubit<JournalDayState>
    implements JournalDayCubit {}

void main() {
  late _MockCubit cubit;
  final today = DateTime(2026, 10, 14);

  JournalDay dayWith({DateTime? date}) => JournalDayComposer.compose(
    JournalDaySources(
      timetable: timetableOf({
        (Weekday.wed, 's1'): 'maths-7a',
        (Weekday.wed, 's4'): 'maths-8a',
      }),
      courses: const {},
      entries: [entryOf(coursId: 'maths-7a', date: today, slot: 's1')],
      chapters: const {},
      calendar: const JournalCalendar(courseDays: {Weekday.wed}),
    ),
    date: date ?? today,
    today: today,
  );

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.canGoBack).thenReturn(true);
    when(() => cubit.canGoForward).thenReturn(true);
    when(() => cubit.show(any())).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  Future<void> pump(
    WidgetTester tester,
    JournalDayState state, {
    double width = 1400,
    ValueChanged<JournalLine>? onOpen,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      programmeHost(
        BlocProvider<JournalDayCubit>.value(
          value: cubit,
          child: SingleChildScrollView(child: JournalView(onOpen: onOpen)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('chargement : le squelette, l\'en-tête reste là', (tester) async {
    await pump(tester, JournalDayLoading(date: today, today: today));

    expect(find.byType(EteeloListSkeleton), findsOneWidget);
    expect(find.byTooltip('Jour précédent'), findsOneWidget);
  });

  testWidgets('large : la feuille ; toucher une ligne ouvre la saisie', (
    tester,
  ) async {
    final opened = <JournalLine>[];
    await pump(
      tester,
      JournalDayReady(day: dayWith(), date: today, today: today),
      onOpen: opened.add,
    );

    expect(find.byType(JournalSheet), findsOneWidget);
    expect(find.text('Renseignée'), findsOneWidget);
    expect(find.text('À préparer'), findsOneWidget);
    expect(find.textContaining('1/2', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Renseignée'));
    expect(opened.single.coursId, 'maths-7a');
  });

  testWidgets('une séance s\'active au lecteur d\'écran et se lit en entier', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      JournalDayReady(day: dayWith(), date: today, today: today),
      onOpen: (_) {},
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel(
        RegExp(r'^1re heure.*Objectif d.apprentissage : O'),
      ),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('étroit : des cartes', (tester) async {
    await pump(
      tester,
      JournalDayReady(day: dayWith(), date: today, today: today),
      width: 600,
    );

    expect(find.byType(JournalCardList), findsOneWidget);
    expect(find.byType(JournalSheet), findsNothing);
  });

  testWidgets('jour sans cours : vide, et le prochain jour s\'ouvre', (
    tester,
  ) async {
    final thursday = DateTime(2026, 10, 15);
    await pump(
      tester,
      JournalDayReady(
        day: JournalDay(
          date: thursday,
          lines: const [],
          nextCourseDay: DateTime(2026, 10, 21),
        ),
        date: thursday,
        today: today,
      ),
    );

    expect(find.text('Aucun cours ce jour'), findsOneWidget);
    await tester.tap(find.textContaining('21 octobre'));
    verify(() => cubit.show(DateTime(2026, 10, 21))).called(1);
  });

  testWidgets('échec de lecture locale : « Réessayer » relit le jour', (
    tester,
  ) async {
    await pump(
      tester,
      JournalDayFailure(
        failure: const StorageFailure('ko'),
        date: today,
        today: today,
      ),
    );

    expect(find.text('Journal illisible'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    verify(() => cubit.show(today)).called(1);
  });

  testWidgets('aux bornes de l\'année, la navigation est inactive', (
    tester,
  ) async {
    when(() => cubit.canGoBack).thenReturn(false);
    await pump(
      tester,
      JournalDayReady(day: dayWith(), date: today, today: today),
    );

    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    expect(previous.onPressed, isNull);
  });
}
