import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_results_section.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockAttendanceBloc extends MockBloc<AttendanceEvent, AttendanceState>
    implements AttendanceBloc {}

/// Le **câblage** de la garde de correction, pas seulement son exigence.
///
/// L'exigence elle-même est épinglée dans `test/core/auth/attendance_amend_access_test.dart`.
/// Ce fichier-ci répond à l'autre moitié de la question, celle qui a déjà coûté
/// cher au dépôt : une garde peut être écrite, testée, et **jamais branchée**.
/// Rabaisser `isPastCorrection` à `false` dans l'écran ne faisait rougir aucun
/// test — l'écran aurait continué d'offrir l'enregistrement à un enseignant sur
/// un jour révolu, et l'écriture serait morte plus tard en 403 terminal.
void main() {
  const enseignant = <String>['attendance.read', 'attendance.write'];
  const surveillance = <String>[
    'attendance.read',
    'attendance.write',
    'attendance.amend',
  ];

  const classroom = OfflineClassroom(
    id: 'c1',
    academicYearId: 'ay1',
    name: '7e CTEB A',
  );

  AttendanceSearchRequest requestOn(DateTime date) => AttendanceSearchRequest(
    selectedCycle: const AttendanceCycleOption(
      id: 'g1',
      label: 'CTEB',
      displayOrder: 1,
      levels: [],
    ),
    selectedLevel: const AttendanceLevelOption(
      schoolLevelGroupId: 'g1',
      schoolLevelId: 'l1',
      label: '7e',
      displayOrder: 1,
      classrooms: [classroom],
    ),
    selectedClassroom: classroom,
    date: date,
  );

  AttendanceState stateWith({required bool callTaken}) => AttendanceState(
    fetchStatus: AttendanceStatus.success,
    callTaken: callTaken,
    hasUnsavedChanges: true,
    draftRows: const [
      AttendanceEditableRow(
        studentId: 's1',
        studentFirstName: 'Aline',
        studentLastName: 'Mukendi',
        studentGender: StudentGender.female,
        present: true,
        absenceReason: null,
        absenceReasonNote: '',
      ),
    ],
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<String> permissions,
    required DateTime date,
    required bool callTaken,
  }) async {
    final auth = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(
      auth,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    final attendance = _MockAttendanceBloc();
    final attendanceState = stateWith(callTaken: callTaken);
    when(() => attendance.state).thenReturn(attendanceState);
    whenListen(
      attendance,
      Stream<AttendanceState>.value(attendanceState),
      initialState: attendanceState,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: auth),
              BlocProvider<AttendanceBloc>.value(value: attendance),
            ],
            child: AttendanceResultsSection(
              lastRequest: requestOn(date),
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  DateTime yesterday() => DateTime.now().subtract(const Duration(days: 1));

  testWidgets(
    'jour révolu + appel déjà pris : l\'enseignant perd le bouton et lit pourquoi',
    (tester) async {
      await pumpScreen(
        tester,
        permissions: enseignant,
        date: yesterday(),
        callTaken: true,
      );

      expect(find.text('Enregistrer l\'appel'), findsNothing);
      expect(
        find.textContaining('surveillance générale'),
        findsOneWidget,
        reason: 'un écran sans bouton et sans un mot se lit comme une panne',
      );
    },
  );

  testWidgets(
    'jour révolu + appel déjà pris : la surveillance garde le bouton',
    (tester) async {
      await pumpScreen(
        tester,
        permissions: surveillance,
        date: yesterday(),
        callTaken: true,
      );

      expect(find.text('Enregistrer l\'appel'), findsOneWidget);
      expect(find.textContaining('surveillance générale'), findsNothing);
    },
  );

  testWidgets(
    'jour révolu SANS appel pris : prendre l\'appel en retard n\'est pas une correction',
    (tester) async {
      await pumpScreen(
        tester,
        permissions: enseignant,
        date: yesterday(),
        callTaken: false,
      );

      expect(find.text('Enregistrer l\'appel'), findsOneWidget);
    },
  );

  testWidgets(
    'appel DU JOUR déjà pris : rectifier reste le geste de qui constate',
    (tester) async {
      await pumpScreen(
        tester,
        permissions: enseignant,
        date: DateTime.now(),
        callTaken: true,
      );

      expect(find.text('Enregistrer l\'appel'), findsOneWidget);
    },
  );
}
