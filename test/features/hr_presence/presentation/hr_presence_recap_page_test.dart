import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_recap_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_table.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_presence_builders.dart';

class _MockRecap extends Mock implements GetHrAttendanceRecapUseCase {}

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockCount extends Mock implements CountUnsyncedStaffAttendanceUseCase {}

class _MockCommands extends Mock implements StaffAttendanceCommands {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockAuth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  final manage = [
    Perm.hrAttendanceRead.wire,
    Perm.hrAttendanceWrite.wire,
    Perm.hrAttendanceManage.wire,
  ];

  Future<_MockCommands> pump(
    WidgetTester tester, {
    HrAttendanceRecap? answer,
    List<String>? permissions,
    StaffAttendanceLock? lock,
    int unsynced = 0,
    Map<String, Map<String, StaffAttendanceRecord>> records = const {},
    Size? size = const Size(1280, 1600),
  }) async {
    if (size != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
    }
    final recap = _MockRecap();
    final load = _MockLoad();
    final count = _MockCount();
    final commands = _MockCommands();
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(
      () => recap(any()),
    ).thenAnswer((_) async => Right(answer ?? recapOf()));
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => Right(
        StaffAttendanceSnapshot(
          members: const [],
          records: records,
          locks: lock == null
              ? const {}
              : {
                  StaffAttendanceSnapshot.lockKey(lock.kind, lock.periodStart):
                      lock,
                },
          settings: StaffAttendanceSettings.defaults,
          hasEverSynced: true,
        ),
      ),
    );
    when(
      () => count(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(unsynced));
    when(() => commands.closeMonth(any())).thenAnswer(
      (_) async => const StaffAttendanceNotice(
        StaffAttendanceNoticeKind.monthClosed,
        month: '2026-10',
      ),
    );
    final cubit = HrPresenceRecapCubit(
      getRecap: recap,
      loadLocal: load,
      countUnsynced: count,
      commands: commands,
      signals: signals,
      yearStart: DateTime(2026, 9, 1),
      now: () => DateTime(2026, 10, 23, 10),
    );
    addTearDown(cubit.close);
    Widget screen = BlocProvider.value(
      value: cubit..load(),
      child: const HrPresenceRecapScreen(),
    );
    if (permissions != null) {
      final auth = _MockAuth();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => auth.state).thenReturn(state);
      whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
      screen = BlocProvider<AuthBloc>.value(value: auth, child: screen);
    }
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    );
    await tester.pump();
    await tester.pump();
    return commands;
  }

  Finder closeButton() => find.widgetWithText(EteeloButton, 'Clôturer le mois');

  testWidgets('les totaux du serveur et une ligne par agent', (tester) async {
    await pump(tester);

    expect(find.text('17 jours de classe à ce jour'), findsOneWidget);
    // Au bandeau, puis au pied du tableau.
    expect(find.text('92 %'), findsNWidgets(2));
    expect(find.textContaining('368,00'), findsNWidgets(2));
    expect(find.byType(HrPresenceRecapTable), findsOneWidget);
    expect(find.text('MWAMBA Clarisse'), findsOneWidget);
  });

  testWidgets('chaque ligne porte l\'œil de l\'app', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
  });

  testWidgets('sans hr.pay.read, ni montant ni colonne d\'argent', (
    tester,
  ) async {
    await pump(tester, answer: recapOf(withAmounts: false));
    expect(find.textContaining('368,00'), findsNothing);
  });

  testWidgets('le bandeau garde le mois et dit ce qui manque', (tester) async {
    await pump(tester, unsynced: 2);

    expect(find.text('RÉCAPITULATIF POUR LA PAIE'), findsOneWidget);
    expect(find.text('Jours non pointés'), findsOneWidget);
    expect(find.text('Encore sur la tablette'), findsOneWidget);
    // La carte de clôture le redit en une ligne.
    expect(
      find.textContaining('6 jours-agent non pointés', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('absences et retards sur deux lignes, NJ d\'abord', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.textContaining('3 NJ · 1 J', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('1 retard · 12 min'), findsWidgets);
    expect(find.text('Total · 3 agents'), findsOneWidget);
  });

  testWidgets('la pastille dit l\'agent dont un pointage attend l\'envoi', (
    tester,
  ) async {
    await pump(
      tester,
      records: {
        'a-1': {
          '2026-10-22': const StaffAttendanceRecord(
            id: 'r-1',
            staffMemberId: 'a-1',
            workDate: '2026-10-22',
            status: PresenceStatus.present,
            syncState: RecordSyncState.pending,
          ),
        },
      },
    );

    expect(find.text('Sur la tablette'), findsOneWidget);
  });

  testWidgets('filtré, le tableau perd son total', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(EteeloFilterChip, 'Vacataire'));
    await tester.pump();

    expect(find.text('KALALA Didier'), findsOneWidget);
    expect(find.text('MWAMBA Clarisse'), findsNothing);
    expect(find.textContaining('Total ·'), findsNothing);
  });

  testWidgets('E2 : seule la direction voit « Clôturer »', (tester) async {
    await pump(
      tester,
      permissions: [Perm.hrAttendanceRead.wire, Perm.hrAttendanceWrite.wire],
    );
    expect(closeButton(), findsNothing);
  });

  testWidgets('E5 : avant le dernier jour, le bouton est désarmé et le dit', (
    tester,
  ) async {
    await pump(tester, permissions: manage);

    final button = tester.widget<EteeloButton>(closeButton());
    expect(button.onPressed, isNull);
    expect(
      find.text('Clôture possible à partir du samedi 31 octobre 2026'),
      findsOneWidget,
    );
  });

  testWidgets('un mois fini se clôt après confirmation, sans « transmettre »', (
    tester,
  ) async {
    final commands = await pump(
      tester,
      permissions: manage,
      answer: recapOf(closable: true),
    );
    await tester.ensureVisible(closeButton());
    await tester.tap(closeButton());
    await tester.pumpAndSettle();
    expect(find.textContaining('Transmettre'), findsNothing);
    expect(
      find.text(
        'Un mois clôturé ne se rouvre pas : la paie validée en dépend.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(EteeloButton, 'Clôturer').last);
    await tester.pumpAndSettle();

    verify(() => commands.closeMonth('2026-10')).called(1);
  });

  testWidgets('un mois clos le dit, sans bouton', (tester) async {
    await pump(tester, permissions: manage, answer: recapOf(closed: true));

    expect(find.textContaining('Mois clôturé'), findsOneWidget);
    expect(closeButton(), findsNothing);
  });

  testWidgets('un mois de vacances : rien à clôturer', (tester) async {
    await pump(tester, answer: recapOf(classDays: 0, staff: const []));
    expect(find.byType(PresenceHolidayState), findsOneWidget);
  });

  testWidgets('une clôture refusée par le serveur se dit', (tester) async {
    await pump(
      tester,
      permissions: manage,
      answer: recapOf(month: '2026-10', closable: true),
      lock: const StaffAttendanceLock(
        kind: StaffAttendanceLockKind.month,
        periodStart: '2026-10-01',
        locked: false,
        syncState: RecordSyncState.failed,
      ),
    );
    expect(find.textContaining('refusée par le serveur'), findsOneWidget);
  });

  testWidgets('un mois passé non clôturable ne promet pas de date', (
    tester,
  ) async {
    await pump(tester, permissions: manage, answer: recapOf(toDate: false));
    expect(find.textContaining('Clôture possible'), findsNothing);
  });

  testAtReferenceFormats('le récapitulatif tient', (tester, format) async {
    await pump(tester, size: null, permissions: manage, unsynced: 3);
    expect(find.byType(HrPresenceRecapTable), findsOneWidget);
  });

  testAtReferenceFormats('le récapitulatif clos tient', (tester, format) async {
    await pump(
      tester,
      size: null,
      permissions: manage,
      answer: recapOf(closed: true),
    );
    expect(find.textContaining('Mois clôturé'), findsOneWidget);
  });

  testAtReferenceFormats('la clôture en attente d\'envoi tient', (
    tester,
    format,
  ) async {
    await pump(
      tester,
      size: null,
      permissions: manage,
      lock: const StaffAttendanceLock(
        kind: StaffAttendanceLockKind.month,
        periodStart: '2026-10-01',
        locked: true,
        syncState: RecordSyncState.pending,
      ),
    );
    expect(find.textContaining('en attente d\'envoi'), findsOneWidget);
  });
}
