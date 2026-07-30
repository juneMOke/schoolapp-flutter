import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_skeleton.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockAttendanceOfflineBloc
    extends MockBloc<AttendanceOfflineEvent, AttendanceOfflineState>
    implements AttendanceOfflineBloc {}

class MockAcademicYearContextBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class FakeLoadStudentStatsRequested extends Fake
    implements LoadStudentStatsRequested {}

void main() {
  late MockAttendanceOfflineBloc attendanceBloc;
  late MockAcademicYearContextBloc academicYearBloc;

  setUpAll(() {
    registerFallbackValue(FakeLoadStudentStatsRequested());
  });

  setUp(() {
    attendanceBloc = MockAttendanceOfflineBloc();
    academicYearBloc = MockAcademicYearContextBloc();
    whenListen(
      academicYearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: const AcademicYearContextState(
        status: AcademicYearContextLoadStatus.success,
        context: AcademicYearContext(
          academicYear: AcademicYear(
            id: 'ay1',
            name: '2025-2026',
            current: true,
          ),
          schoolLevelGroups: [],
        ),
      ),
    );
  });

  void stubState(AttendanceOfflineState state) {
    whenListen(
      attendanceBloc,
      const Stream<AttendanceOfflineState>.empty(),
      initialState: state,
    );
  }

  StudentAttendanceStats stats({
    StatsPeriod period = StatsPeriod.year,
    int daysCalled = 10,
    List<StudentAbsenceEntry> entries = const [],
    bool bootstrapComplete = true,
  }) => StudentAttendanceStats(
    period: period,
    from: period == StatsPeriod.year ? null : DateTime(2026, 5, 1),
    to: period == StatsPeriod.year ? null : DateTime(2026, 5, 31),
    daysCalled: daysCalled,
    entries: entries,
    bootstrapComplete: bootstrapComplete,
  );

  Widget harness() => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<AttendanceOfflineBloc>.value(value: attendanceBloc),
          BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
        ],
        child: const StudentAttendanceSummaryTab(
          studentId: 's1',
          academicYearId: 'ay1',
        ),
      ),
    ),
  );

  testWidgets(
    'au montage : dispatch LoadStudentStatsRequested (période année)',
    (tester) async {
      stubState(const AttendanceOfflineInitial());

      await tester.pumpWidget(harness());
      await tester.pump();

      verify(
        () => attendanceBloc.add(
          any(
            that: isA<LoadStudentStatsRequested>()
                .having((e) => e.studentId, 'studentId', 's1')
                .having((e) => e.academicYearId, 'academicYearId', 'ay1')
                .having((e) => e.period, 'period', StatsPeriod.year),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets('loading/initial : squelette', (tester) async {
    stubState(const AttendanceOfflineLoading());

    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.byType(PresenceSummarySkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erreur : AttendanceResultsErrorState + Réessayer redispatch', (
    tester,
  ) async {
    stubState(const AttendanceOfflineError('boom'));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));
    clearInteractions(attendanceBloc);

    expect(find.text('Réessayer'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    verify(
      () => attendanceBloc.add(any(that: isA<LoadStudentStatsRequested>())),
    ).called(1);
  });

  testWidgets(
    'available=false (bootstrap incomplet) : état "en attente de synchro" + retry',
    (tester) async {
      stubState(AttendanceOfflineStatsLoaded(stats(bootstrapComplete: false)));

      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 300));
      clearInteractions(attendanceBloc);

      expect(find.text('Synchronisation en cours'), findsOneWidget);
      // Les chiffres ne sont jamais affichés tant que non fiables.
      expect(find.text('Aucun jour scolaire'), findsNothing);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      verify(
        () => attendanceBloc.add(any(that: isA<LoadStudentStatsRequested>())),
      ).called(1);
    },
  );

  testWidgets('available=true mais daysCalled=0 : "aucun jour scolaire"', (
    tester,
  ) async {
    stubState(AttendanceOfflineStatsLoaded(stats(daysCalled: 0)));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aucun jour scolaire'), findsOneWidget);
    expect(find.text('Synchronisation en cours'), findsNothing);
  });

  testWidgets('assiduité parfaite : PresencePerfectCard, pas de liste', (
    tester,
  ) async {
    stubState(AttendanceOfflineStatsLoaded(stats(daysCalled: 20)));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Assiduité parfaite'), findsOneWidget);
    expect(find.text('Détail des absences'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avec absences : carte de synthèse + détail dépliable', (
    tester,
  ) async {
    stubState(
      AttendanceOfflineStatsLoaded(
        stats(
          daysCalled: 20,
          entries: [
            StudentAbsenceEntry(
              date: DateTime(2026, 5, 4),
              reason: AbsenceReason.sickness,
            ),
            StudentAbsenceEntry(
              date: DateTime(2026, 5, 6),
              reason: AbsenceReason.unjustified,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Synthèse de présence'), findsOneWidget);
    expect(find.text('Détail des absences'), findsOneWidget);
    expect(find.text('Assiduité parfaite'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changement de période : redispatch avec la nouvelle période', (
    tester,
  ) async {
    stubState(AttendanceOfflineStatsLoaded(stats(daysCalled: 20)));

    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 300));
    clearInteractions(attendanceBloc);

    await tester.tap(find.text('Mois'));
    await tester.pump();

    verify(
      () => attendanceBloc.add(
        any(
          that: isA<LoadStudentStatsRequested>().having(
            (e) => e.period,
            'period',
            StatsPeriod.month,
          ),
        ),
      ),
    ).called(1);
  });
}
