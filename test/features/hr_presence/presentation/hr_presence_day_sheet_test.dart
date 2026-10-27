import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_day_sheet.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';
import '../hr_presence_builders.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockSave extends Mock implements SaveStaffAttendanceUseCase {}

class _MockGesture extends Mock
    implements RecordStaffAttendanceGestureUseCase {}

class _MockSettings extends Mock
    implements SaveStaffAttendanceSettingsUseCase {}

/// Ce que la feuille a rendu, et ce qu'elle a demandé.
class _Run {
  HrPresenceDayEdit? edit;
  bool registered = false;
  bool closed = false;
  late _MockSave save;
}

/// La feuille du jour : la carte du registre quand la tablette et le serveur
/// s'accordent, sinon la lecture seule et le renvoi au registre.
void main() {
  const day = '2026-09-28';

  setUpAll(() => registerFallbackValue(<StaffAttendanceRecord>[]));

  HrAttendanceDay server({PresenceStatus status = PresenceStatus.none}) =>
      HrAttendanceDay(
        date: day,
        status: status,
        arrival: status.hasArrival ? '07:30' : null,
        lateMinutes: 0,
        workedMinutes: 0,
        future: false,
      );

  StaffAttendanceSnapshot snapshotOf({
    Map<String, StaffAttendanceLock> locks = const {},
  }) => StaffAttendanceSnapshot(
    members: [member('a-1', lastName: 'Kalala', firstName: 'Didier')],
    records: const {},
    locks: locks,
    settings: StaffAttendanceSettings.defaults,
    schoolYear: const SchoolYearBounds(start: '2026-09-01'),
    hasEverSynced: true,
  );

  /// Ouvre la feuille ; rend ce qu'elle a rendu, et si le registre a été
  /// demandé.
  Future<_Run> open(
    WidgetTester tester, {
    required HrAttendanceDay day,
    StaffAttendanceSnapshot? snapshot,
    List<String> permissions = const [],
  }) async {
    // La tablette relit ce qu'elle vient d'écrire, comme la vraie base.
    var current = snapshot ?? snapshotOf();
    final load = _MockLoad();
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(current));
    final save = _MockSave();
    when(() => save(any())).thenAnswer((invocation) async {
      final records =
          invocation.positionalArguments.first as List<StaffAttendanceRecord>;
      current = StaffAttendanceSnapshot(
        members: current.members,
        records: {
          for (final record in records)
            record.staffMemberId: {record.workDate: record},
        },
        locks: current.locks,
        settings: current.settings,
        schoolYear: current.schoolYear,
        hasEverSynced: true,
      );
      return const Right(unit);
    });
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(() => signals.pull()).thenAnswer((_) async {});
    final auth = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: [Perm.hrAttendanceRead.wire, ...permissions],
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: authState);

    final run = _Run()..save = save;
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  run.edit = await showHrPresenceDaySheet(
                    context,
                    agent: agentMonthOf().agent,
                    server: day,
                    onOpenRegister: () => run.registered = true,
                    createCubit: () => StaffAttendanceCubit(
                      load: load,
                      signals: signals,
                      commands: StaffAttendanceCommands(
                        save: save,
                        gesture: _MockGesture(),
                        settings: _MockSettings(),
                        now: () => DateTime(2026, 9, 29, 7, 35),
                      ),
                      now: () => DateTime(2026, 9, 29, 7, 35),
                    ),
                  );
                  run.closed = true;
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return run;
  }

  final write = [Perm.hrAttendanceWrite.wire];

  testWidgets('la tablette et le serveur s\'accordent : la carte du registre', (
    tester,
  ) async {
    await open(tester, day: server(), permissions: write);

    expect(find.textContaining('Pointage du'), findsOneWidget);
    expect(find.byType(StaffAttendanceCard), findsOneWidget);
  });

  testWidgets('le serveur a un pointage que la tablette n\'a pas : lecture '
      'seule, et le registre en sortie', (tester) async {
    await open(
      tester,
      day: server(status: PresenceStatus.present),
      permissions: write,
    );

    expect(find.byType(StaffAttendanceCard), findsNothing);
    expect(find.textContaining('pas encore reçu ce jour'), findsOneWidget);
    expect(find.text('Arrivée 07:30'), findsOneWidget);
    expect(find.text('Ouvrir dans le registre'), findsOneWidget);
  });

  testWidgets('le registre demandé referme la feuille', (tester) async {
    final run = await open(
      tester,
      day: server(status: PresenceStatus.present),
      permissions: write,
    );
    await tester.tap(find.text('Ouvrir dans le registre'));
    await tester.pumpAndSettle();

    expect(run.registered, isTrue);
    expect(run.closed, isTrue);
    expect(run.edit, isNull);
  });

  testWidgets('un geste dans la carte part en file et revient à la fiche', (
    tester,
  ) async {
    final run = await open(tester, day: server(), permissions: write);

    // Toucher la carte fait avancer son statut, comme dans le registre.
    await tester.tap(
      find
          .descendant(
            of: find.byType(StaffAttendanceCard),
            matching: find.textContaining('Kalala'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    verify(() => run.save(any())).called(1);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(run.closed, isTrue);
    expect(run.edit, isNotNull);
  });

  testWidgets('un jour validé : lecture seule, rouvrir dans le registre', (
    tester,
  ) async {
    await open(
      tester,
      day: server(),
      permissions: write,
      snapshot: snapshotOf(
        locks: {
          StaffAttendanceSnapshot.lockKey(
            StaffAttendanceLockKind.day,
            day,
          ): const StaffAttendanceLock(
            kind: StaffAttendanceLockKind.day,
            periodStart: day,
            locked: true,
          ),
        },
      ),
    );

    expect(find.byType(StaffAttendanceCard), findsNothing);
    expect(
      find.textContaining('rapport de ce jour est validé'),
      findsOneWidget,
    );
    expect(find.text('Ouvrir dans le registre'), findsOneWidget);
  });

  testWidgets('sans droit d\'écriture : lecture seule, pas de registre', (
    tester,
  ) async {
    await open(tester, day: server());

    expect(find.byType(StaffAttendanceCard), findsNothing);
    expect(find.textContaining('sans pouvoir le modifier'), findsOneWidget);
    expect(find.text('Ouvrir dans le registre'), findsNothing);
  });

  testAtReferenceFormats('la feuille du jour tient', (tester, format) async {
    await open(tester, day: server(), permissions: write);
    expect(find.byType(StaffAttendanceCard), findsOneWidget);
  });

  testAtReferenceFormats('la lecture seule tient', (tester, format) async {
    await open(
      tester,
      day: server(status: PresenceStatus.present),
      permissions: write,
    );
    expect(find.text('Ouvrir dans le registre'), findsOneWidget);
  });
}
