import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_register_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';
import '../../staff/staff_builders.dart';

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockSave extends Mock implements SaveStaffAttendanceUseCase {}

class _MockGesture extends Mock
    implements RecordStaffAttendanceGestureUseCase {}

class _MockSettings extends Mock
    implements SaveStaffAttendanceSettingsUseCase {}

void main() {
  final snapshot = StaffAttendanceSnapshot(
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
    records: const {},
    locks: const {},
    settings: StaffAttendanceSettings.defaults,
    schoolYear: const SchoolYearBounds(start: '2026-09-01'),
    hasEverSynced: true,
  );

  Future<void> pump(WidgetTester tester) async {
    final load = _MockLoad();
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(() => signals.pull()).thenAnswer((_) async {});
    when(
      () => load(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(snapshot));
    final cubit = StaffAttendanceCubit(
      load: load,
      signals: signals,
      commands: StaffAttendanceCommands(
        save: _MockSave(),
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
            child: const HrPresenceRegisterScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('le registre seul : ses cartes, sans les onglets du Pointage', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(StaffAttendanceCard), findsNWidgets(2));
    expect(
      find.textContaining('Le préfet ou le censeur pointe'),
      findsOneWidget,
    );
    expect(find.text('Fiche mensuelle'), findsNothing);
    expect(find.text('Récapitulatif du mois'), findsNothing);
  });

  testAtReferenceFormats('le registre en cartes tient', (tester, format) async {
    await pump(tester);
    expect(find.byType(StaffAttendanceCard), findsWidgets);
  });

  testAtReferenceFormats('le registre en liste tient', (tester, format) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Liste'));
    await tester.tap(find.text('Liste'));
    await tester.pump();
    expect(find.byType(StaffAttendanceRow), findsWidgets);
  });
}
