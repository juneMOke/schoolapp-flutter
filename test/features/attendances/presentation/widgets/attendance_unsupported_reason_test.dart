import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
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

/// Le **câblage** de la garde « motif non reconnu », pas seulement la sentinelle.
///
/// La sentinelle est épinglée dans `absence_reason_test.dart`. Ici on répond à
/// l'autre moitié : l'écran s'en sert-il ? Une garde peut être écrite, testée,
/// et jamais reliée — la suite reste alors verte pendant que la porte est
/// ouverte, et l'enregistrement réécrit le motif du serveur en silence.
void main() {
  const classroom = OfflineClassroom(
    id: 'c1',
    academicYearId: 'ay1',
    name: '7e CTEB A',
  );

  AttendanceSearchRequest request() => AttendanceSearchRequest(
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
    date: DateTime.now(),
  );

  Future<void> pumpWithReason(WidgetTester tester, AbsenceReason reason) async {
    final auth = _MockAuthBloc();
    const authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: ['attendance.read', 'attendance.write'],
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(
      auth,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    final attendance = _MockAttendanceBloc();
    final attendanceState = AttendanceState(
      fetchStatus: AttendanceStatus.success,
      callTaken: true,
      hasUnsavedChanges: true,
      draftRows: [
        AttendanceEditableRow(
          studentId: 's1',
          studentFirstName: 'Aline',
          studentLastName: 'Mukendi',
          studentGender: StudentGender.female,
          present: false,
          absenceReason: reason,
          absenceReasonNote: '',
        ),
      ],
    );
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
              lastRequest: request(),
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  EteeloButton saveButton(WidgetTester tester) => tester.widget<EteeloButton>(
    find.widgetWithText(EteeloButton, 'Enregistrer l\'appel'),
  );

  testWidgets(
    'motif non reconnu : enregistrement bloqué, et l\'écran dit pourquoi',
    (tester) async {
      await pumpWithReason(tester, AbsenceReason.unsupported);

      expect(find.textContaining('ne connaît pas'), findsOneWidget);
      expect(
        saveButton(tester).onPressed,
        isNull,
        reason:
            'laisser passer réécrirait le motif du serveur sans que personne '
            'le voie — l\'écran renvoie TOUTES les lignes du brouillon',
      );
    },
  );

  testWidgets('motif connu : rien ne bloque (contre-épreuve)', (tester) async {
    // Sans elle, une garde qui bloquerait TOUJOURS passerait pour correcte.
    await pumpWithReason(tester, AbsenceReason.sickness);

    expect(find.textContaining('ne connaît pas'), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('la sentinelle est dans les options de SA ligne', (tester) async {
    // Le select ne lève plus sur une valeur absente de ses options — mais la
    // ligne afficherait alors un champ vide là où l'enseignant a mis un motif.
    // On l'affirme sur les OPTIONS plutôt que sur un libellé affiché, pour que
    // l'échec désigne la cause au lieu d'une conséquence.
    await pumpWithReason(tester, AbsenceReason.unsupported);

    final champ = tester.widget<EteeloSelectInput<AbsenceReason>>(
      find.byType(EteeloSelectInput<AbsenceReason>),
    );
    expect(
      champ.items.map((item) => item.value),
      contains(AbsenceReason.unsupported),
    );
  });

  testWidgets('un motif connu n\'ajoute PAS la sentinelle aux options', (
    tester,
  ) async {
    await pumpWithReason(tester, AbsenceReason.sickness);

    final champ = tester.widget<EteeloSelectInput<AbsenceReason>>(
      find.byType(EteeloSelectInput<AbsenceReason>),
    );
    expect(
      champ.items.map((item) => item.value),
      isNot(contains(AbsenceReason.unsupported)),
    );
  });
}
