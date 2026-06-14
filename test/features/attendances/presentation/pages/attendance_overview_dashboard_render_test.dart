import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/absence_reason_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_bucket.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_weekday.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/class_attendance_stat.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/top_absent_class.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/weekday_absence_stat.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/attendance_overview_dashboard_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_empty_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_reasons_section.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_success_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockAttendanceOverviewBloc
    extends MockBloc<AttendanceOverviewEvent, AttendanceOverviewState>
    implements AttendanceOverviewBloc {}

StatsContext _context() => StatsContext(
  schoolYear: '2025-2026',
  period: 'month',
  periodStart: DateTime(2026, 4, 1),
  periodEnd: DateTime(2026, 4, 30),
  generatedAt: DateTime(2026, 6, 12, 8, 14),
);

AttendanceOverview _richOverview() => AttendanceOverview(
  context: _context(),
  kpis: const AttendanceKpis(
    presenceRate: 92.4,
    justifiedAbsenceRate: 5.1,
    unjustifiedAbsenceRate: 2.5,
    recordedDays: 21,
    presentDays: 9240,
    justifiedAbsenceDays: 510,
    unjustifiedAbsenceDays: 250,
  ),
  evolution: const AttendanceEvolution(
    granularity: AttendanceEvolutionGranularity.week,
    currentBucketIndex: 3,
    buckets: [
      AttendanceEvolutionBucket(
        key: 'S1',
        presenceRate: 91.5,
        recordedDays: 5,
        isCurrent: false,
      ),
      AttendanceEvolutionBucket(
        key: 'S2',
        presenceRate: 90.8,
        recordedDays: 5,
        isCurrent: false,
      ),
      AttendanceEvolutionBucket(
        key: 'S3',
        presenceRate: 93.2,
        recordedDays: 5,
        isCurrent: false,
      ),
      AttendanceEvolutionBucket(
        key: 'S4',
        presenceRate: 92.4,
        recordedDays: 6,
        isCurrent: true,
      ),
    ],
  ),
  byClass: const [
    ClassAttendanceStat(
      cycle: 'Maternelle',
      level: '3e Maternelle',
      classroomId: 'c1',
      className: '3e Maternelle A',
      presenceRate: 95.1,
      justifiedAbsenceRate: 3.4,
      unjustifiedAbsenceRate: 1.5,
      recordedDays: 21,
    ),
    ClassAttendanceStat(
      cycle: 'Secondaire',
      level: '8e EB',
      classroomId: 'c2',
      className: '8e EB A',
      presenceRate: 88.1,
      justifiedAbsenceRate: 6.9,
      unjustifiedAbsenceRate: 5.0,
      recordedDays: 21,
    ),
  ],
  topAbsentClasses: const [
    TopAbsentClass(
      classroomId: 'c2',
      className: '8e EB A',
      level: 'Secondaire',
      absenceRate: 11.9,
      absenceDays: 250,
    ),
    TopAbsentClass(
      classroomId: 'c3',
      className: '7e EB A',
      level: 'Secondaire',
      absenceRate: 10.8,
      absenceDays: 228,
    ),
  ],
  byAbsenceReason: const [
    AbsenceReasonStats(reason: AbsenceReason.sickness, absenceDays: 228),
    AbsenceReasonStats(reason: AbsenceReason.familyEmergency, absenceDays: 137),
    AbsenceReasonStats(reason: null, absenceDays: 250),
    AbsenceReasonStats(reason: AbsenceReason.other, absenceDays: 23),
  ],
  byWeekday: const [
    WeekdayAbsenceStat(
      weekday: AttendanceWeekday.monday,
      absenceRate: 6.8,
      recordedDays: 4,
    ),
    WeekdayAbsenceStat(
      weekday: AttendanceWeekday.wednesday,
      absenceRate: 9.4,
      recordedDays: 4,
    ),
    WeekdayAbsenceStat(
      weekday: AttendanceWeekday.friday,
      absenceRate: 11.2,
      recordedDays: 4,
    ),
  ],
);

/// Données dégénérées : taux à 0 et toutes les listes vides — exerce les
/// garde-fous (division par zéro, charts/listes vides, flex 0).
AttendanceOverview _degenerateOverview() => AttendanceOverview(
  context: _context(),
  kpis: const AttendanceKpis(
    presenceRate: 0,
    justifiedAbsenceRate: 0,
    unjustifiedAbsenceRate: 0,
    recordedDays: 3,
    presentDays: 0,
    justifiedAbsenceDays: 0,
    unjustifiedAbsenceDays: 0,
  ),
  evolution: const AttendanceEvolution(
    granularity: AttendanceEvolutionGranularity.month,
    currentBucketIndex: 0,
  ),
);

Widget _wrapBody(Widget child, {double width = 1000}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: widget!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets('SuccessView renders rich data without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapBody(AttendanceOverviewSuccessView(overview: _richOverview())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Quelques ancres de rendu (libellés FR).
    expect(find.text('Présence par classe'), findsOneWidget);
    expect(find.text('Taux de présence'), findsOneWidget);
    expect(find.text('Classes les plus absentéistes'), findsOneWidget);
  });

  testWidgets('SuccessView renders degenerate (zero/empty) data safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapBody(AttendanceOverviewSuccessView(overview: _degenerateOverview())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('ReasonsSection with many reasons does not overflow (wide donut)', (
    tester,
  ) async {
    // Largeur >= 760 dp côté donut -> layout Row + légende latérale (la branche
    // sujette au débordement). 9 segments -> légende haute -> doit défiler.
    const manyReasons = [
      AbsenceReasonStats(reason: AbsenceReason.sickness, absenceDays: 100),
      AbsenceReasonStats(
        reason: AbsenceReason.familyEmergency,
        absenceDays: 90,
      ),
      AbsenceReasonStats(reason: AbsenceReason.personal, absenceDays: 80),
      AbsenceReasonStats(reason: AbsenceReason.vacation, absenceDays: 70),
      AbsenceReasonStats(
        reason: AbsenceReason.underGraduateLeave,
        absenceDays: 60,
      ),
      AbsenceReasonStats(reason: AbsenceReason.marriageLeave, absenceDays: 50),
      AbsenceReasonStats(reason: AbsenceReason.parentalLeave, absenceDays: 40),
      AbsenceReasonStats(reason: AbsenceReason.workLeave, absenceDays: 30),
      AbsenceReasonStats(reason: null, absenceDays: 200),
    ];
    await tester.pumpWidget(
      _wrapBody(
        const AttendanceOverviewReasonsSection(reasons: manyReasons),
        width: 900,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardSkeleton renders without exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapBody(const AttendanceOverviewDashboardSkeleton()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('EmptyView renders without exceptions', (tester) async {
    await tester.pumpWidget(
      _wrapBody(AttendanceOverviewEmptyView(onTakeAttendance: () {})),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Aucune donnée de présence'), findsOneWidget);
  });

  group('Dashboard page state switching', () {
    Widget pageWith(AttendanceOverviewState state) {
      final bloc = MockAttendanceOverviewBloc();
      whenListen(
        bloc,
        const Stream<AttendanceOverviewState>.empty(),
        initialState: state,
      );
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: widget!,
        ),
        home: BlocProvider<AttendanceOverviewBloc>.value(
          value: bloc,
          child: const AttendanceOverviewDashboardPage(),
        ),
      );
    }

    testWidgets('loading -> skeleton', (tester) async {
      await tester.pumpWidget(
        pageWith(
          const AttendanceOverviewState(
            status: AttendanceOverviewStatus.loading,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AttendanceOverviewDashboardSkeleton), findsOneWidget);
    });

    testWidgets('success -> success view (with context bar)', (tester) async {
      await tester.pumpWidget(
        pageWith(
          AttendanceOverviewState(
            status: AttendanceOverviewStatus.success,
            overview: _richOverview(),
            selectedPeriod: StatsPeriod.month,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AttendanceOverviewSuccessView), findsOneWidget);
    });

    testWidgets('success with recordedDays==0 -> empty view', (tester) async {
      await tester.pumpWidget(
        pageWith(
          AttendanceOverviewState(
            status: AttendanceOverviewStatus.success,
            overview: AttendanceOverview(
              context: _context(),
              kpis: const AttendanceKpis(
                presenceRate: 0,
                justifiedAbsenceRate: 0,
                unjustifiedAbsenceRate: 0,
                recordedDays: 0,
                presentDays: 0,
                justifiedAbsenceDays: 0,
                unjustifiedAbsenceDays: 0,
              ),
              evolution: const AttendanceEvolution(
                granularity: AttendanceEvolutionGranularity.month,
                currentBucketIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AttendanceOverviewEmptyView), findsOneWidget);
    });

    testWidgets('failure -> error state', (tester) async {
      await tester.pumpWidget(
        pageWith(
          const AttendanceOverviewState(
            status: AttendanceOverviewStatus.failure,
            errorType: AttendanceErrorType.network,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AttendanceResultsErrorState), findsOneWidget);
    });
  });
}
