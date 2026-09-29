import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_attendance_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_time_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_row.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_validated_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff_builders.dart';

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockSave extends Mock implements SaveStaffAttendanceUseCase {}

class _MockGesture extends Mock
    implements RecordStaffAttendanceGestureUseCase {}

class _MockSettings extends Mock
    implements SaveStaffAttendanceSettingsUseCase {}

const _day = '2026-09-29';

void main() {
  late _MockLoad load;
  late _MockSave save;

  setUpAll(() => registerFallbackValue(<StaffAttendanceRecord>[]));

  StaffAttendanceSnapshot snapshotOf({bool validated = false}) =>
      StaffAttendanceSnapshot(
        members: [
          member(
            'm-1',
            lastName: 'Kalala',
            firstName: 'Didier',
            contracts: [
              period(StaffContractKind.vacataire, payMode: StaffPayMode.hourly),
            ],
          ),
          member('m-2', lastName: 'Mayala', firstName: 'Ruth'),
        ],
        records: {
          'm-2': {
            _day: StaffAttendanceRecord(
              id: 'r-2',
              staffMemberId: 'm-2',
              workDate: _day,
              status: StaffAttendanceStatus.late,
              arrival: StaffClockTime.tryParse('07:52'),
              lateMinutes: 22,
            ),
          },
        },
        locks: {
          if (validated)
            StaffAttendanceSnapshot.lockKey(
              StaffAttendanceLockKind.day,
              _day,
            ): const StaffAttendanceLock(
              kind: StaffAttendanceLockKind.day,
              periodStart: _day,
              locked: true,
              lockedAt: '2026-09-29T15:02:00Z',
            ),
        },
        settings: StaffAttendanceSettings.defaults,
        hasEverSynced: true,
      );

  Future<StaffAttendanceCubit> pump(
    WidgetTester tester, {
    bool validated = false,
    Size size = const Size(1280, 1000),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    load = _MockLoad();
    save = _MockSave();
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(() => signals.pull()).thenAnswer((_) async {});
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(snapshotOf(validated: validated)));
    when(() => save(any())).thenAnswer((_) async => const Right(unit));
    final cubit = StaffAttendanceCubit(
      load: load,
      signals: signals,
      commands: StaffAttendanceCommands(
        save: save,
        gesture: _MockGesture(),
        settings: _MockSettings(),
        now: () => DateTime(2026, 9, 29, 7, 35),
      ),
      now: () => DateTime(2026, 9, 29, 7, 35),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit..load(),
            child: const StaffAttendanceScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return cubit;
  }

  testWidgets('le registre montre une carte par agent et les onglets', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(StaffAttendanceCard), findsNWidgets(2));
    expect(find.text('Registre du jour'), findsWidgets);
    expect(find.text('Fiche mensuelle'), findsOneWidget);
    expect(find.text('Récapitulatif du mois'), findsOneWidget);
    // Le vacataire à l'heure porte son badge.
    expect(find.text('VAC · H'), findsOneWidget);
  });

  testWidgets('toucher une carte « à pointer » la pointe présente', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Kalala Mutombo'));
    await tester.pump();

    final records =
        verify(() => save(captureAny())).captured.single
            as List<StaffAttendanceRecord>;
    expect(records.single.staffMemberId, 'm-1');
    expect(records.single.status, StaffAttendanceStatus.present);
    expect(records.single.arrival, StaffClockTime.tryParse('07:35'));
  });

  testWidgets('la liste donne un segment de statut par agent', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Liste'));
    await tester.pump();

    expect(find.byType(StaffAttendanceRow), findsNWidgets(2));
  });

  testWidgets('un jour validé montre le bandeau et refuse les gestes', (
    tester,
  ) async {
    await pump(tester, validated: true);

    expect(find.byType(StaffValidatedBanner), findsOneWidget);
    await tester.tap(find.text('Kalala Mutombo'));
    await tester.pump();

    verifyNever(() => save(any()));
    expect(
      find.text(
        'Rapport du jour validé — rouvrez-le pour modifier un pointage',
      ),
      findsOneWidget,
    );
  });

  testWidgets('le récapitulatif ouvre la fiche d\'un agent', (tester) async {
    final cubit = await pump(tester);

    await tester.tap(find.text('Récapitulatif du mois'));
    await tester.pump();
    await tester.tap(find.text('Ruth Mayala'));
    await tester.pump();

    expect(cubit.state.agentId, 'm-2');
    expect(find.text('Retards et absences du mois'), findsOneWidget);
  });

  testWidgets('la modale d\'heure tient en paysage, clavier ouvert', (
    tester,
  ) async {
    await pump(tester, size: const Size(731, 411));

    await tester.ensureVisible(find.text('07:52'));
    await tester.tap(find.text('07:52'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(find.byType(StaffTimeDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
