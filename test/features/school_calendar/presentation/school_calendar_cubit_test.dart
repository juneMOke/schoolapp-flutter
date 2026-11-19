import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_cubit.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';

import 'fake_calendar_repository.dart';

void main() {
  late FakeCalendarRepository repository;
  late SchoolCalendarCubit cubit;

  setUp(() async {
    repository = FakeCalendarRepository();
    cubit = SchoolCalendarCubit(
      repository,
      schoolToday: () => DateTime(2026, 6, 10, 23, 30),
    );
    await cubit.load();
  });
  tearDown(() => cubit.close());

  test('la liste trouve le calendrier en vigueur', () {
    expect(cubit.state.status, SchoolCalendarStatus.ready);
    expect(cubit.state.inForce!.yearLabel, '2025-2026');
    expect(
      cubit.state.phaseOf(cubit.state.library.calendars[1]),
      CalendarPhase.draft,
    );
  });

  test(
    'ouvrir un calendrier : mois en cours, cadre + événements, rythme majoritaire',
    () async {
      await cubit.open('2025-2026');
      final state = cubit.state;
      expect(state.month, d(2026, 6, 1));
      expect(state.effectiveRhythm, PeriodRhythm.semester);
      expect(state.allElements.map((e) => e.id), ['p-s', 'ferie', 'reunion']);
      cubit.setRhythm(PeriodRhythm.trimester);
      expect(cubit.state.allElements.map((e) => e.id), [
        'p-t',
        'ferie',
        'reunion',
      ]);
    },
  );

  test('un brouillon s’ouvre à son premier mois', () async {
    await cubit.open('2026-2027');
    expect(cubit.state.month, d(2026, 9, 1));
  });

  test('légende, source et « à vérifier » filtrent', () async {
    await cubit.open('2025-2026');
    cubit.toggleNature(CalendarNature.publicHoliday);
    expect(cubit.state.visibleElements.map((e) => e.id), ['p-s', 'reunion']);
    cubit.toggleNature(CalendarNature.publicHoliday);
    cubit.setSource(CalendarSourceFilter.school);
    expect(cubit.state.visibleElements.map((e) => e.id), ['reunion']);
    cubit.setSource(CalendarSourceFilter.all);
    cubit.setVerifyOnly(true);
    expect(cubit.state.view, CalendarView.list);
    expect(cubit.state.visibleElements.map((e) => e.id), ['reunion']);
    expect(cubit.state.toVerifyCount, 1);
  });

  test('le mois ne sort pas de l’année', () async {
    await cubit.open('2025-2026');
    cubit.shiftMonth(1);
    expect(cubit.state.month, d(2026, 7, 1));
    cubit.shiftMonth(1);
    expect(cubit.state.month, d(2026, 7, 1));
  });

  test('toucher un jour le sélectionne, le retoucher le libère', () async {
    await cubit.open('2025-2026');
    cubit.selectDay(d(2026, 6, 9));
    expect(cubit.state.selectedDay, d(2026, 6, 9));
    cubit.selectDay(d(2026, 6, 9));
    expect(cubit.state.selectedDay, isNull);
  });

  test('« date vérifiée » enregistre l’élément sans la marque', () async {
    await cubit.open('2025-2026');
    await cubit.verify(cubit.state.events.single.element);
    expect(repository.saved.single.toVerify, isFalse);
  });

  test('créer ouvre le brouillon rendu', () async {
    final result = await cubit.create('2027-2028');
    expect(result.isRight(), isTrue);
    expect(cubit.state.openYear, '2027-2028');
  });
}
