import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_day_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_picker.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_consultation.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_summary.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/consultation_actions.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_draft_section.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_kpi_band.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../../test_helpers/reference_formats.dart';

const _classroom = TimetableClassOption(
  classroomId: 'c7a',
  name: '7e CTEB A',
  cycleCode: 'SEC',
  cycleName: 'Secondaire',
  levelCode: 'CTEB7',
  levelName: '7e CTEB',
  room: 'Salle 12',
);

const _courses = [
  TimetableCourse(
    coursId: 'math',
    classroomId: 'c7a',
    branchId: 'b1',
    branchLabel: 'Mathématiques',
    domainId: 'sci',
    domainLabel: 'Sciences',
    domainOrder: 1,
    teacherId: 't1',
    teacherLabel: 'Kashala',
    weeklyHours: 2,
  ),
  TimetableCourse(
    coursId: 'fr',
    classroomId: 'c7a',
    branchId: 'b2',
    branchLabel: 'Français',
    domainId: 'lang',
    domainLabel: 'Langues',
    domainOrder: 2,
    teacherId: 't2',
    teacherLabel: 'Ilunga',
    weeklyHours: 1,
  ),
];

/// Lundi : maths, maths ; mardi : français ; les autres créneaux sont libres.
ClassTimetableView _view({
  bool draft = false,
  DateTime? publishedAt,
  int extraMath = 0,
}) {
  final slots = [
    for (final (i, (s, e)) in [
      ('07:30', '08:20'),
      ('08:20', '09:10'),
      ('10:20', '11:10'),
    ].indexed)
      TimeSlot(id: 's$i', order: i + 1, startTime: '$s:00', endTime: '$e:00'),
  ];
  ClassTimetableCell cell(Weekday day, int slot, TimetableCourse c) =>
      ClassTimetableCell(
        id: '${day.wire}$slot',
        classroomId: 'c7a',
        classroomLabel: '7e CTEB A',
        status: draft
            ? TimetableCellStatus.draft
            : TimetableCellStatus.published,
        draftId: draft ? 'd' : null,
        day: day,
        slotId: 's$slot',
        range: MinuteRange(450 + slot * 50, 500 + slot * 50),
        coursId: c.coursId,
        teacherId: c.teacherId,
        subjectLabel: c.branchLabel,
        teacherLabel: c.teacherLabel,
      );
  final cells = [
    cell(Weekday.mon, 0, _courses[0]),
    cell(Weekday.mon, 1, _courses[0]),
    cell(Weekday.tue, 0, _courses[1]),
    for (var i = 0; i < extraMath; i++) cell(Weekday.wed, i, _courses[0]),
  ];
  return ClassTimetableView(
    classroom: _classroom,
    grid: const TimeGrid(
      id: 'g',
      name: 'Secondaire',
      isDefault: true,
      recess: MinuteRange(600, 620),
    ),
    slots: slots,
    header: ClassTimetableHeader(
      id: 'h',
      classroomId: 'c7a',
      academicYearId: 'y',
      revision: 1,
      publishedVersion: 1,
      publishedAt: publishedAt,
      publishedBy: const TimetableActor(name: 'Mme Mavinga', role: 'CP'),
      draftId: draft ? 'd' : null,
    ),
    published: cells,
    draft: draft ? cells : const [],
    programme: _courses,
    othersKnown: true,
  );
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

class _Cubit extends MockCubit<ClassTimetableState>
    implements ClassTimetableCubit {}

void main() {
  group('choix de la classe (EDT §4.6 A)', () {
    testWidgets('téléphone debout : les trois champs, pas de repli', (
      tester,
    ) async {
      setTestWindow(tester, const Size(390, 780));
      await tester.pumpWidget(
        _host(
          ClassPicker(
            options: const [_classroom],
            selectedId: 'c7a',
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('Emplois du temps par classe'), findsOneWidget);
      expect(find.text('Changer'), findsNothing);
      expect(find.text('Classe'), findsOneWidget);
    });

    testWidgets('fenêtre basse : une ligne et « Changer » (I23)', (
      tester,
    ) async {
      setTestWindow(tester, const Size(740, 360));
      await tester.pumpWidget(
        _host(
          ClassPicker(
            options: const [_classroom],
            selectedId: 'c7a',
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('7e CTEB A · Secondaire › 7e CTEB'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'Changer')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Changer'));
      await tester.pumpAndSettle();
      expect(find.text('Classe'), findsOneWidget);
    });
  });

  group('identité et pavés (EDT §4.6 B)', () {
    testWidgets('publié : la date, l’heure et l’auteur', (tester) async {
      setTestWindow(tester, const Size(1280, 900));
      final view = _view(publishedAt: DateTime.utc(2026, 3, 2, 8, 14));
      await tester.pumpWidget(
        _host(ClassTimetableSummary(view: view, cells: view.published)),
      );
      expect(
        find.text('Publié le 2 mars 2026 · 09:14 par Mme Mavinga (CP)'),
        findsOneWidget,
      );
      expect(find.text('CONFLITS'), findsOneWidget);
    });

    testWidgets('publié sans date connue : jamais « Jamais publié »', (
      tester,
    ) async {
      setTestWindow(tester, const Size(1280, 900));
      final view = _view();
      await tester.pumpWidget(
        _host(ClassTimetableSummary(view: view, cells: view.published)),
      );
      expect(find.text('Publié'), findsOneWidget);
      expect(find.text('Jamais publié'), findsNothing);
    });

    testWidgets('brouillon : le statut « Brouillon » seul', (tester) async {
      setTestWindow(tester, const Size(1280, 900));
      final view = _view(draft: true);
      await tester.pumpWidget(
        _host(
          ClassTimetableSummary(view: view, cells: view.draft, draft: true),
        ),
      );
      expect(find.text('Brouillon'), findsOneWidget);
      expect(find.text('Publié'), findsNothing);
    });

    testWidgets('un excès d’heures ne se dit pas « volume complet » (R5)', (
      tester,
    ) async {
      setTestWindow(tester, const Size(1280, 900));
      final view = _view(extraMath: 2);
      await tester.pumpWidget(
        _host(ClassTimetableSummary(view: view, cells: view.published)),
      );
      expect(find.text('5 / 3'), findsOneWidget);
      expect(find.text('+2 h'), findsOneWidget);
      expect(find.text('volume complet'), findsNothing);
    });

    testWidgets('sous 600 : Séances et Enseignants en texte, « En cours » '
        'sur toute la ligne', (tester) async {
      setTestWindow(tester, const Size(390, 780));
      final view = _view();
      await tester.pumpWidget(
        _host(ClassTimetableSummary(view: view, cells: view.published)),
      );
      expect(find.text('3 séances / semaine · 2 enseignants'), findsOneWidget);
      expect(find.text('SÉANCES / SEMAINE'), findsNothing);
      expect(find.text('CONFLITS'), findsOneWidget);
    });
  });

  group('actions et semaine (EDT §4.6 C)', () {
    testWidgets('consultation : Imprimer, Copier…, Modifier', (tester) async {
      setTestWindow(tester, const Size(1280, 900));
      final view = _view(publishedAt: DateTime.utc(2026, 3, 2));
      final cubit = _Cubit();
      final state = ClassTimetableState(view: view);
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.thisWeek).thenReturn(DateTime.utc(2026, 6, 8));
      await tester.pumpWidget(
        _host(
          ClassTimetableConsultation(
            state: state,
            cubit: cubit,
            view: view,
            onEdit: () {},
            onCopy: () {},
            // Mercredi 10 juin 2026, 07:40 à Kinshasa.
            clock: () => DateTime.utc(2026, 6, 10, 6, 40),
          ),
        ),
      );
      expect(find.byType(ClassTimetableModeSwitch), findsOneWidget);
      expect(find.text('Imprimer'), findsOneWidget);
      expect(find.text('Copier…'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      // L'en-tête sombre : la date, les heures du jour, aujourd'hui.
      expect(find.text('8 juin · 2 h'), findsOneWidget);
      expect(find.text('Aujourd’hui · 0 h'), findsNothing);
      expect(find.textContaining('Aujourd'), findsWidgets);
      expect(find.byType(TimetableNowPave), findsOneWidget);
    });

    testWidgets('R12 : le brouillon reste en semaine au téléphone, sans '
        'bascule', (tester) async {
      setTestWindow(tester, const Size(390, 780));
      final view = _view(draft: true);
      final cubit = _Cubit();
      when(() => cubit.state).thenReturn(ClassTimetableState(view: view));
      await tester.pumpWidget(
        _host(TimetableDraftSection(view: view, cubit: cubit, online: true)),
      );
      expect(find.byType(ScheduleWeekGrid), findsOneWidget);
      expect(find.byType(ClassTimetableModeSwitch), findsNothing);
      expect(find.text('Jour'), findsNothing);
      // Sous 760 reçus, libellés courts ; la semaine défile, « Suite » la
      // montre (I14).
      expect(find.text('Lun.'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Suite'), findsOneWidget);
    });
  });

  testWidgets('journée : « Pas de cours » et la récréation s’intercalent '
      '(EDT §4.6 E)', (tester) async {
    setTestWindow(tester, const Size(390, 780));
    final view = _view();
    await tester.pumpWidget(
      _host(
        ClassDayView(
          timetable: ClassWeekBuilder.build(view, view.published),
          palette: ScheduleClassPalette.byCourse(
            ClassWeekBuilder.courseVisuals(view),
          ),
          today: null,
          selectedDay: Weekday.tue,
          onDaySelected: (_) {},
          domains: const {'math': 'Sciences', 'fr': 'Langues'},
          onOpenCell: (_) {},
          dates: {
            for (final day in Weekday.values)
              day: DateTime.utc(2026, 6, 8 + day.index),
          },
        ),
      ),
    );
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Pas de cours'), findsNWidgets(2));
    expect(find.textContaining('RÉCRÉATION'), findsOneWidget);
    expect(find.byTooltip('Voir la séance'), findsOneWidget);
    expect(find.text('9 juin'), findsOneWidget);
  });

  testAtReferenceFormats('consultation et brouillon tiennent à tous les '
      'formats', (tester, format) async {
    final view = _view(publishedAt: DateTime.utc(2026, 3, 2));
    final cubit = _Cubit();
    final state = ClassTimetableState(view: view);
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.thisWeek).thenReturn(DateTime.utc(2026, 6, 8));
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            ClassTimetableConsultation(
              state: state,
              cubit: cubit,
              view: view,
              onEdit: () {},
              onCopy: () {},
              clock: () => DateTime.utc(2026, 6, 10, 6, 40),
            ),
            TimetableDraftSection(
              view: _view(draft: true),
              cubit: cubit,
              online: true,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Mathématiques'), findsWidgets);
  });
}
