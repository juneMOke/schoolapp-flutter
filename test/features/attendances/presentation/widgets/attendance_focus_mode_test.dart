import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_focus_mode.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_reason_grid.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_records_mobile_list.dart';
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

/// Le mode Focus de la passe des motifs : quand il s'offre, sur qui il porte.
///
/// Le lot est une affaire de CADRAGE, pas de widget : un Focus sur l'effectif
/// entier serait plus lent que la liste qu'il remplace, le flux dominant étant
/// « tout le monde est là sauf trois ». Ces cas épinglent donc les deux bornes
/// — il ne se propose que s'il reste des motifs, et il n'itère que sur les
/// absents.
void main() {
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
      classrooms: [
        OfflineClassroom(id: 'c1', academicYearId: 'ay1', name: '7e CTEB A'),
      ],
    ),
    selectedClassroom: const OfflineClassroom(
      id: 'c1',
      academicYearId: 'ay1',
      name: '7e CTEB A',
    ),
    date: DateTime.now(),
  );

  AttendanceEditableRow row(
    String id,
    String prenom, {
    required bool present,
    AbsenceReason? reason,
  }) => AttendanceEditableRow(
    studentId: id,
    studentFirstName: prenom,
    studentLastName: 'Mukendi',
    studentGender: StudentGender.female,
    present: present,
    absenceReason: reason,
    absenceReasonNote: '',
  );

  Future<AttendanceBloc> pump(
    WidgetTester tester,
    List<AttendanceEditableRow> rows,
  ) async {
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
      draftRows: rows,
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
    return attendance;
  }

  /// Alias lisible là où le test se sert du bloc renvoyé.
  Future<AttendanceBloc> pumpAndReturnBloc(
    WidgetTester tester,
    List<AttendanceEditableRow> rows,
  ) => pump(tester, rows);

  testWidgets('aucun motif manquant : la bascule ne se propose pas', (
    tester,
  ) async {
    // La borne haute du cadrage. Sans elle, le Focus deviendrait un détour de
    // quarante passages pour un appel où tout est déjà renseigné.
    await pump(tester, [
      row('s1', 'Aline', present: true),
      row('s2', 'Bea', present: false, reason: AbsenceReason.sickness),
    ]);

    expect(find.byType(SegmentedTabFilter<AttendanceEntryMode>), findsNothing);
  });

  testWidgets(
    'un motif manquant : la bascule apparaît et compte ce qui reste',
    (tester) async {
      await pump(tester, [
        row('s1', 'Aline', present: true),
        row('s2', 'Bea', present: false),
      ]);

      expect(
        find.byType(SegmentedTabFilter<AttendanceEntryMode>),
        findsOneWidget,
      );
      expect(find.textContaining('1 motif à renseigner'), findsOneWidget);
    },
  );

  testWidgets('le Focus n\'itère QUE sur les absents', (tester) async {
    await pump(tester, [
      row('s1', 'Aline', present: true),
      row('s2', 'Bea', present: false),
      row('s3', 'Chantal', present: false, reason: AbsenceReason.personal),
    ]);

    await tester.tap(find.text('Focus'));
    await tester.pump();

    // Deux absents sur trois élèves : la carte annonce « 1 / 2 », jamais 3.
    expect(find.byType(AttendanceFocusMode), findsOneWidget);
    expect(find.byType(AttendanceRecordsMobileList), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
    // La présente n'a pas de carte.
    expect(find.textContaining('Aline'), findsNothing);
  });

  testWidgets('le motif se choisit en grande cible, pas en dropdown', (
    tester,
  ) async {
    await pump(tester, [
      row('s1', 'Aline', present: false),
      row('s2', 'Bea', present: false),
    ]);
    await tester.tap(find.text('Focus'));
    await tester.pump();

    // Le geste que le mode existe pour économiser : un menu rouvert à chaque
    // élève coûte deux taps, une cible en coûte un.
    expect(find.byType(AttendanceReasonGrid), findsOneWidget);
    expect(
      find.byType(EteeloSelectInput<AbsenceReason>),
      findsNothing,
      reason: 'la carte Focus ne doit plus porter le select de la liste',
    );
    // Les cinq motifs de saisie sont des cibles, pas des entrées de menu.
    for (final motif in kSelectableAbsenceReasons) {
      expect(
        find.text(
          motif.getDisplayName(
            AppLocalizations.of(
              tester.element(find.byType(AttendanceReasonGrid)),
            )!,
          ),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('poser un motif avance à l\'absent suivant', (tester) async {
    final bloc = await pumpAndReturnBloc(tester, [
      row('s1', 'Aline', present: false),
      row('s2', 'Bea', present: false),
    ]);
    await tester.tap(find.text('Focus'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.text('Maladie'));
    await tester.pump();

    // L'événement part…
    verify(
      () => bloc.add(
        const AttendanceAbsenceReasonChanged(
          studentId: 's1',
          absenceReason: AbsenceReason.sickness,
        ),
      ),
    ).called(1);
    // …et la carte a avancé : c'est ce qui rend la passe faisable en un tap
    // par élève.
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('depuis le DERNIER absent, poser un motif n\'avance pas', (
    tester,
  ) async {
    // Contre-épreuve : avancer depuis le dernier sortirait de la carte et
    // laisserait l'écran sans rien montrer.
    await pumpAndReturnBloc(tester, [row('s1', 'Aline', present: false)]);
    await tester.tap(find.text('Focus'));
    await tester.pump();

    await tester.tap(find.text('Maladie'));
    await tester.pump();

    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('la liste reste le mode par défaut', (tester) async {
    // Contre-épreuve : un Focus imposé d'office serait exactement le détour
    // que ce cadrage existe pour éviter.
    await pump(tester, [row('s2', 'Bea', present: false)]);

    expect(find.byType(AttendanceRecordsMobileList), findsOneWidget);
    expect(find.byType(AttendanceFocusMode), findsNothing);
  });
}
