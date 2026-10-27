import 'package:bloc_test/bloc_test.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_fiche_sheet.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_scope_bar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_year_list.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../hr_presence_builders.dart';

class _MockMonth extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockYear extends Mock implements GetHrAttendanceAgentYearUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

class _MockReport extends Mock implements GetHrAttendanceReportUseCase {}

class _MockSheet extends Mock implements GetHrAttendanceAgentSheetUseCase {}

class _MockLoadAttendance extends Mock implements LoadStaffAttendanceUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

StaffFileSnapshot _file() => StaffFileSnapshot(
  members: [
    member('a-1', lastName: 'KABASELE-TSHIMANGA', firstName: 'Marie-Béatrice'),
    member('a-2', lastName: 'Mayala', firstName: 'Ruth'),
  ],
  documentsByMember: const {},
  documentTypes: const [],
  hasEverSynced: true,
);

void main() {
  late _MockSheet sheet;

  /// [attendance] : ce que la tablette sait (verrous, pointages) ; `null` :
  /// pas de lecture locale. [permissions] : `null` monte sans session (la
  /// porte laisse tout passer).
  Future<({_MockMonth month, _MockYear year})> pump(
    WidgetTester tester, {
    bool yearly = false,
    HrAttendanceAgentYear? year,
    Size? size = const Size(1280, 1400),
    StaffAttendanceSnapshot? attendance,
    List<String>? permissions,
  }) async {
    if (size != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
    }
    final answerYear = year;
    final month = _MockMonth();
    final yearMock = _MockYear();
    final source = _MockSource();
    // Le fichier local nourrit le sélecteur : posé, il entre dans la mise en
    // page aux formats.
    when(() => source.read()).thenAnswer((_) async => Right(_file()));
    when(
      () => month(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
    when(
      () => yearMock(any()),
    ).thenAnswer((_) async => Right(answerYear ?? agentYearOf()));
    _MockLoadAttendance? load;
    if (attendance != null) {
      load = _MockLoadAttendance();
      when(
        () => load!(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right(attendance));
    }
    sheet = _MockSheet();
    when(
      () => sheet(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => const Left(ServerFailure('—')));
    final report = HrAttendanceReportCubit(
      getReport: _MockReport(),
      getAgentSheet: sheet,
    );
    addTearDown(report.close);
    final cubit = HrPresenceFicheCubit(
      getMonth: month,
      getYear: yearMock,
      source: source,
      loadAttendance: load,
      args: (
        agentId: 'a-1',
        yearly: yearly,
        month: '2026-10',
        yearStart: DateTime(2026, 9, 1),
      ),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _withSession(
          permissions,
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit..load()),
              BlocProvider.value(value: report),
            ],
            child: const HrPresenceFicheAgentScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (month: month, year: yearMock);
  }

  testWidgets('vue mensuelle : le profil du mois, ses taux, son calendrier', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Profil · octobre 2026'), findsOneWidget);
    expect(find.text('Absentéiste'), findsOneWidget);
    expect(find.text('Taux de retard'), findsOneWidget);
    expect(find.text('2 jours sur 3 pointés'), findsOneWidget);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
    // La tendance appartient au détail du tableau de bord, pas à la fiche.
    expect(find.text('Tendance sur six mois'), findsNothing);
  });

  testWidgets('vue annuelle : un mois de classe ouvre sa vue mensuelle ; un '
      'mois à venir ne s\'ouvre pas', (tester) async {
    final mocks = await pump(tester, yearly: true);

    expect(find.byType(HrPresenceYearList), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    await tester.tap(find.text('novembre 2026'));
    await tester.pump();
    expect(find.byType(HrPresenceYearList), findsOneWidget);

    await tester.tap(find.text('septembre 2026'));
    await tester.pump();
    await tester.pump();
    verify(() => mocks.month('a-1', month: '2026-09')).called(1);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
  });

  testWidgets('la fiche mensuelle en une feuille : la règle chiffrée, et le '
      'détail de chaque jour dans le calendrier', (tester) async {
    await pump(tester);

    expect(find.byType(HrPresenceFicheSheet), findsOneWidget);
    // La portée vit dans la feuille, pas dans une carte à part.
    expect(find.byType(HrPresenceScopeBar), findsOneWidget);
    expect(find.textContaining('jours de classe'), findsOneWidget);
    // Un présent écrit son arrivée dans sa case.
    expect(find.text('07:25'), findsWidgets);
  });

  testWidgets('vue annuelle en table : une colonne par taux, l\'année en '
      'pied', (tester) async {
    await pump(tester, yearly: true);

    expect(find.byType(EteeloColumnTable), findsOneWidget);
    // Les en-têtes de table s'écrivent en majuscules.
    for (final header in ['MOIS', 'RÉPARTITION', 'PRÉSENCE', 'PROFIL']) {
      expect(find.text(header), findsOneWidget);
    }
    // Septembre : trois taux, chacun dans sa colonne, et ses jours pointés.
    expect(find.text('95 %'), findsOneWidget);
    expect(find.text('22 / 22'), findsOneWidget);
    // Le pied totalise les jours de classe des mois (22 + 17).
    expect(find.text('Année'), findsOneWidget);
    expect(find.textContaining('/ 39'), findsOneWidget);
  });

  testWidgets('la bascule Annuelle relit l\'année', (tester) async {
    final mocks = await pump(tester);
    await tester.tap(find.text('Annuelle'));
    await tester.pump();
    await tester.pump();
    verify(() => mocks.year('a-1')).called(1);
  });

  testWidgets('entre deux années, la vue annuelle le dit', (tester) async {
    await pump(
      tester,
      yearly: true,
      year: HrAttendanceAgentYear(
        schoolYear: null,
        agent: agentMonthOf().agent,
        profile: PresenceProfile.notEvaluated,
        kpis: kpisOf(),
        months: const [],
      ),
    );
    expect(find.text('Aucune année scolaire en cours'), findsOneWidget);
  });

  testAtReferenceFormats('la fiche mensuelle tient', (tester, format) async {
    await pump(tester, size: null);
    expect(find.byType(PresenceMonthCalendar), findsOneWidget);
  });

  testAtReferenceFormats('la fiche annuelle tient', (tester, format) async {
    await pump(tester, size: null, yearly: true);
    expect(find.byType(HrPresenceYearList), findsOneWidget);
  });

  StaffAttendanceSnapshot attendanceOf({
    bool monthClosed = false,
    int unsent = 0,
  }) => StaffAttendanceSnapshot(
    members: const [],
    records: {
      'a-1': {
        for (var i = 0; i < unsent; i++)
          '2026-10-0${i + 1}': StaffAttendanceRecord(
            id: 'r-$i',
            staffMemberId: 'a-1',
            workDate: '2026-10-0${i + 1}',
            status: PresenceStatus.present,
            syncState: RecordSyncState.pending,
          ),
      },
    },
    locks: {
      if (monthClosed)
        StaffAttendanceSnapshot.lockKey(
          StaffAttendanceLockKind.month,
          '2026-10-01',
        ): const StaffAttendanceLock(
          kind: StaffAttendanceLockKind.month,
          periodStart: '2026-10-01',
          locked: true,
        ),
    },
    settings: StaffAttendanceSettings.defaults,
    hasEverSynced: true,
  );

  testWidgets('le PDF du mois demande la fiche de ce mois', (tester) async {
    await pump(tester, attendance: attendanceOf());

    expect(
      find.byTooltip(
        'Télécharger la fiche de présence : provisoire, la '
        'période n\'est pas close',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.pump();
    verify(() => sheet('a-1', month: '2026-10')).called(1);
  });

  testWidgets('le PDF de l\'année demande l\'année', (tester) async {
    await pump(tester, yearly: true);
    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.pump();
    verify(() => sheet('a-1', month: null)).called(1);
  });

  testWidgets('un mois clos sans droit d\'émission : pas de bouton PDF', (
    tester,
  ) async {
    await pump(
      tester,
      attendance: attendanceOf(monthClosed: true),
      permissions: [Perm.hrAttendanceRead.wire],
    );
    expect(find.text('PDF'), findsNothing);
  });

  testWidgets('un mois clos avec le droit d\'émission : pièce scellée', (
    tester,
  ) async {
    await pump(
      tester,
      attendance: attendanceOf(monthClosed: true),
      permissions: [Perm.hrAttendanceRead.wire, Perm.editiqueWrite.wire],
    );
    expect(
      find.byTooltip(
        'Télécharger la fiche de présence du mois clos : pièce scellée',
      ),
      findsOneWidget,
    );
  });

  testWidgets('des pointages non envoyés : on prévient avant le tirage', (
    tester,
  ) async {
    await pump(tester, attendance: attendanceOf(unsent: 2));
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 pointages de cet agent'), findsOneWidget);
    verifyNever(() => sheet(any(), month: any(named: 'month')));
    await tester.tap(find.text('Télécharger quand même'));
    await tester.pump();
    await tester.pump();
    verify(() => sheet('a-1', month: '2026-10')).called(1);
  });
}

/// Une session portant [permissions] ; `null` : pas de session.
Widget _withSession(List<String>? permissions, Widget child) {
  if (permissions == null) return child;
  final auth = _MockAuthBloc();
  final state = AuthState(
    status: AuthStatus.authenticated,
    permissions: permissions,
  );
  when(() => auth.state).thenReturn(state);
  whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
  return BlocProvider<AuthBloc>.value(value: auth, child: child);
}
