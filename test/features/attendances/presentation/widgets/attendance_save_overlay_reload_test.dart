import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_save_overlay.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAttendanceBloc extends MockBloc<AttendanceEvent, AttendanceState>
    implements AttendanceBloc {}

class _MockOfflineBloc
    extends MockBloc<AttendanceOfflineEvent, AttendanceOfflineState>
    implements AttendanceOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// Ce que la feuille d'appel doit devenir une fois l'appel écrit.
///
/// L'overlay confirmait l'écriture et laissait l'écran derrière lui dans l'état
/// d'AVANT : bandeau « appel non fait » alors que la session existe, brouillon
/// toujours réputé modifié, bouton d'enregistrement encore actif — et, sur un
/// jour révolu, une correction qui échappait à la garde d'amendement puisque
/// l'écran croyait encore l'appel jamais pris.
void main() {
  final date = DateTime(2026, 5, 12);

  late _MockAttendanceBloc attendanceBloc;
  late _MockOfflineBloc offlineBloc;
  late _MockSyncStatusCubit syncCubit;
  late StreamController<AttendanceOfflineState> offlineStates;

  final attendanceState = AttendanceState(
    fetchStatus: AttendanceStatus.success,
    callTaken: false,
    activeClassroomId: 'c1',
    activeAcademicYearId: 'ay1',
    activeDate: date,
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

  setUp(() {
    attendanceBloc = _MockAttendanceBloc();
    when(() => attendanceBloc.state).thenReturn(attendanceState);
    whenListen(
      attendanceBloc,
      const Stream<AttendanceState>.empty(),
      initialState: attendanceState,
    );

    offlineBloc = _MockOfflineBloc();
    offlineStates = StreamController<AttendanceOfflineState>.broadcast();
    whenListen(
      offlineBloc,
      offlineStates.stream,
      initialState: const AttendanceOfflineInitial(),
    );

    syncCubit = _MockSyncStatusCubit();
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});
  });

  tearDown(() => offlineStates.close());

  Future<void> open(WidgetTester tester) async {
    // L'anatomie d'erreur partagée est plus haute que la surface de test par
    // défaut (800x600) : on rend sur une tablette, pas sur un mouchoir.
    await tester.binding.setSurfaceSize(const Size(1024, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SyncStatusCubit>.value(value: syncCubit),
          BlocProvider<AttendanceBloc>.value(value: attendanceBloc),
          BlocProvider<AttendanceOfflineBloc>.value(value: offlineBloc),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AttendanceSaveOverlay(
              classroomName: '7e CTEB A',
              date: date,
              presentCount: 1,
              justifiedCount: 0,
              unjustifiedCount: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'écriture locale confirmée : la journée est relue pour l\'écran de dessous',
    (tester) async {
      await open(tester);

      verify(
        () => offlineBloc.add(
          RecordDailyAttendanceRequested(
            classroomId: 'c1',
            date: date,
            academicYearId: 'ay1',
            updates: attendanceState.draftRows
                .map((row) => row.toUpdate())
                .toList(growable: false),
          ),
        ),
      ).called(1);

      offlineStates.add(const AttendanceOfflinePendingSync());
      await tester.pump();

      verify(
        () => attendanceBloc.add(
          AttendanceFetchRequested(
            classroomId: 'c1',
            date: date,
            academicYearId: 'ay1',
          ),
        ),
      ).called(1);
    },
  );

  testWidgets('écriture locale en échec : rien n\'est relu', (tester) async {
    await open(tester);

    offlineStates.add(const AttendanceOfflineError('base indisponible'));
    await tester.pump();

    verifyNever(
      () => attendanceBloc.add(
        AttendanceFetchRequested(
          classroomId: 'c1',
          date: date,
          academicYearId: 'ay1',
        ),
      ),
    );
  });
}
