import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
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

/// « Tout le monde est là » doit pouvoir s'enregistrer.
///
/// C'est le cas le PLUS fréquent, et c'était le seul qu'on ne pouvait pas
/// enregistrer : appel non fait ⇒ le roster est présenté « présent par défaut »,
/// donc le brouillon est identique aux enregistrements, donc `hasUnsavedChanges`
/// est faux, donc le bouton restait gris — et le bandeau « appel non fait » ne
/// pouvait jamais tomber.
void main() {
  const enseignant = <String>['attendance.read', 'attendance.write'];

  const classroom = OfflineClassroom(
    id: 'c1',
    academicYearId: 'ay1',
    name: '7e CTEB A',
  );

  final request = AttendanceSearchRequest(
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

  /// Feuille d'appel où PERSONNE n'est absent et où rien n'a été touché : le
  /// brouillon est le miroir exact de ce qui est en base.
  AttendanceState allPresentUntouched({required bool callTaken}) =>
      AttendanceState(
        fetchStatus: AttendanceStatus.success,
        callTaken: callTaken,
        hasUnsavedChanges: false,
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

  Future<void> pumpScreen(WidgetTester tester, AttendanceState state) async {
    // Le panneau de résultats se dimensionne sur la hauteur d'écran : la
    // surface de test par défaut (800x600) est sous sa hauteur minimale, et la
    // colonne déborde dès qu'un bandeau s'ajoute. On teste sur une tablette.
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = _MockAuthBloc();
    const authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: enseignant,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(
      auth,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    final attendance = _MockAttendanceBloc();
    when(() => attendance.state).thenReturn(state);
    whenListen(
      attendance,
      Stream<AttendanceState>.value(state),
      initialState: state,
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
              lastRequest: request,
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

  testWidgets('appel non fait + tout le monde présent : le bouton enregistre', (
    tester,
  ) async {
    await pumpScreen(tester, allPresentUntouched(callTaken: false));

    expect(
      saveButton(tester).onPressed,
      isNotNull,
      reason: 'zéro absent n\'est pas zéro appel : c\'est un appel à confirmer',
    );
  });

  testWidgets('appel déjà fait et rien de changé : le bouton reste inerte', (
    tester,
  ) async {
    await pumpScreen(tester, allPresentUntouched(callTaken: true));

    expect(
      saveButton(tester).onPressed,
      isNull,
      reason:
          'réenregistrer à l\'identique ne ferait que repousser au serveur '
          'un agrégat qu\'il détient déjà',
    );
  });

  testWidgets(
    'un absent sans motif : le bouton reste inerte même appel non fait',
    (tester) async {
      await pumpScreen(
        tester,
        const AttendanceState(
          fetchStatus: AttendanceStatus.success,
          callTaken: false,
          hasUnsavedChanges: true,
          hasValidationErrors: true,
          draftRows: [
            AttendanceEditableRow(
              studentId: 's1',
              studentFirstName: 'Aline',
              studentLastName: 'Mukendi',
              studentGender: StudentGender.female,
              present: false,
              absenceReason: null,
              absenceReasonNote: '',
            ),
          ],
        ),
      );

      expect(saveButton(tester).onPressed, isNull);
    },
  );
}
