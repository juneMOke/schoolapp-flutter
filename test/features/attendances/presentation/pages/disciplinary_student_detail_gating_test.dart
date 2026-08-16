import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/pages/disciplinary_student_detail_page.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_body.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_open_cases_pill.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockCaseBloc
    extends MockBloc<DisciplinaryCaseOfflineEvent, DisciplinaryCaseOfflineState>
    implements DisciplinaryCaseOfflineBloc {}

class _MockAttendanceBloc
    extends MockBloc<AttendanceOfflineEvent, AttendanceOfflineState>
    implements AttendanceOfflineBloc {}

class _MockYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockSyncDisciplinaryPullUseCase extends Mock
    implements SyncDisciplinaryPullUseCase {}

/// ADR-015 §6-A — la fiche élève est gardée par la route sur son SECOND segment
/// (`presences`), donc sur `attendance.read`. Sans garde interne, un profil qui
/// ne fait que l'appel voyait l'onglet « Discipline » et une pastille verte
/// « Aucun cas ouvert » : une affirmation qu'il n'a pas le droit de vérifier, et
/// qui est fausse dès que l'élève est sous sanction.
///
/// Le BLoC des cas est ici TOUJOURS chargé d'un cas OUVERT : la pastille doit
/// donc être tue par le DROIT, jamais par l'absence de données.
void main() {
  setUpAll(() {
    registerFallbackValue(
      const LoadOfflineDisciplinaryCases(
        studentId: 's1',
        academicYearId: 'ay1',
      ),
    );
  });

  const surveillant = <String>['attendance.read', 'discipline.read'];
  const appelSeul = <String>['attendance.read'];

  final caseData = OfflineDisciplinaryCase(
    id: 'case-1',
    studentId: 's1',
    studentFirstName: 'Awa',
    studentLastName: 'Diop',
    studentGender: StudentGender.female,
    academicYearId: 'ay1',
    disciplinaryCaseDate: DateTime(2026, 7, 1),
    title: 'Bavardage en classe',
    content: 'Détail du cas',
    category: DisciplinaryCategory.talkingInClass,
    severity: DisciplinarySeverity.minor,
    status: DisciplinaryStatus.open,
    updatedAt: 0,
  );

  const intent = DisciplinaryStudentDetailIntent(
    studentId: 's1',
    studentFirstName: 'Awa',
    studentLastName: 'Diop',
    studentGender: 'FEMALE',
    academicYearId: 'ay1',
    levelName: '6e',
    levelGroupName: 'Secondaire',
    classroomName: '6e A',
  );

  late _MockCaseBloc caseBloc;
  late _MockSyncDisciplinaryPullUseCase syncUseCase;

  setUp(() {
    caseBloc = _MockCaseBloc();
    final loaded = DisciplinaryOfflineCasesLoaded([caseData]);
    when(() => caseBloc.state).thenReturn(loaded);
    whenListen(
      caseBloc,
      Stream<DisciplinaryCaseOfflineState>.value(loaded),
      initialState: loaded,
    );

    syncUseCase = _MockSyncDisciplinaryPullUseCase();
    GetIt.I.registerSingleton<SyncDisciplinaryPullUseCase>(syncUseCase);
  });

  tearDown(() => GetIt.I.reset());

  Widget host(List<String> permissions) {
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    final attendanceBloc = _MockAttendanceBloc();
    when(
      () => attendanceBloc.state,
    ).thenReturn(const AttendanceOfflineInitial());
    whenListen(
      attendanceBloc,
      const Stream<AttendanceOfflineState>.empty(),
      initialState: const AttendanceOfflineInitial(),
    );

    final yearBloc = _MockYearBloc();
    const yearState = AcademicYearContextState.initial();
    when(() => yearBloc.state).thenReturn(yearState);
    whenListen(
      yearBloc,
      const Stream<AcademicYearContextState>.empty(),
      initialState: yearState,
    );

    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<DisciplinaryCaseOfflineBloc>.value(value: caseBloc),
          BlocProvider<AttendanceOfflineBloc>.value(value: attendanceBloc),
          BlocProvider<AcademicYearContextBloc>.value(value: yearBloc),
        ],
        child: const DisciplinaryStudentDetailPage(intent: intent),
      ),
    );
  }

  testWidgets('avec discipline.read : les deux volets et la pastille', (
    tester,
  ) async {
    // Cycle hors-ligne : le socle n'a rien tenté (ADR-015 F6). La page ne lit
    // pas le bilan — elle recharge le local — mais le stub doit exister.
    when(
      () => syncUseCase.call(),
    ).thenAnswer((_) async => const PullRunReport.offline());
    await tester.pumpWidget(host(surveillant));
    await tester.pump();

    expect(find.byType(DisciplinaryDossierBody), findsOneWidget);
    expect(find.byType(DisciplinaryDossierTabs), findsOneWidget);
    final pill = tester.widget<DisciplinaryOpenCasesAppBarPill>(
      find.byType(DisciplinaryOpenCasesAppBarPill),
    );
    expect(pill.openCasesCount, 1);
  });

  testWidgets('sans discipline.read : ni volet, ni barre, ni pastille', (
    tester,
  ) async {
    await tester.pumpWidget(host(appelSeul));
    await tester.pump();

    expect(find.byType(DisciplinaryDossierBody), findsNothing);
    expect(find.byType(DisciplinaryDossierTabs), findsNothing);
    // La synthèse de présence, elle, reste : c'est le volet que la route ouvre.
    expect(find.byType(StudentAttendanceSummaryTab), findsOneWidget);
    // Le compte reste inconnu, donc la pastille se tait — alors même que le
    // BLoC porte un cas OUVERT.
    final pill = tester.widget<DisciplinaryOpenCasesAppBarPill>(
      find.byType(DisciplinaryOpenCasesAppBarPill),
    );
    expect(pill.openCasesCount, isNull);
  });

  testWidgets('sans discipline.read : les cas ne sont ni lus ni tirés', (
    tester,
  ) async {
    await tester.pumpWidget(host(appelSeul));
    await tester.pump();

    verifyNever(() => caseBloc.add(any()));
    verifyNever(() => syncUseCase.call());
  });
}
