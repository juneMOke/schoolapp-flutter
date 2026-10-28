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
import 'package:school_app_flutter/features/hr_presence/data/models/hr_attendance_recap_model.dart';
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
import '../data/hr_attendance_fixtures.dart' as fx;
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
    Map<String, int> unsynced = const {},
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
      () => count.byAgent(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Right(unsynced));
    when(() => commands.reopenMonth(any(), any())).thenAnswer(
      (_) async => const StaffAttendanceNotice(
        StaffAttendanceNoticeKind.monthReopened,
        month: '2026-10',
      ),
    );
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
    // Les heures au bandeau ; au pied, les montants du mois les remplacent.
    expect(find.textContaining('368,00'), findsOneWidget);
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

  testWidgets('pour qui lit la paie : le coût du mois et sa retenue', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Coût de la paie de octobre 2026'), findsOneWidget);
    // Au bandeau et au pied : 824,55 $ et − 65,45 $.
    expect(find.textContaining('824,55'), findsNWidgets(2));
    expect(find.textContaining('− 65,45'), findsNWidgets(3));
    expect(find.text('÷ 22 jours ouvrés'), findsOneWidget);
    expect(find.textContaining('versée début novembre 2026'), findsOneWidget);
    expect(find.text('Prévu'), findsOneWidget);
    // La ligne de MWAMBA : 3 NJ × 21,82 $, le vacataire payé à l'heure.
    expect(find.textContaining('3 j × 21,82'), findsOneWidget);
    expect(find.text('payé à l\'heure'), findsOneWidget);
    expect(find.text('BRUT APRÈS ABSENCES'), findsOneWidget);
    expect(find.text('HEURES VAC.'), findsNothing);
  });

  testWidgets(
    'deux devises : une ligne de total chacune, jamais additionnées',
    (tester) async {
      await pump(tester, answer: recapOf(withCdf: true));
      expect(find.text('Total · 3 agents'), findsOneWidget);
      expect(find.text('Total · USD'), findsOneWidget);
      expect(find.text('Total · CDF'), findsOneWidget);
    },
  );

  testWidgets('une paie validée : chiffres figés', (tester) async {
    await pump(
      tester,
      answer: recapOf(payrollStatus: HrRecapPayrollStatus.validated),
    );
    expect(find.text('Figé'), findsOneWidget);
    expect(find.text('Paie validée : chiffres figés'), findsOneWidget);
  });

  testWidgets('une école qui ne retient pas : ni colonne ni tuile de retenue', (
    tester,
  ) async {
    await pump(tester, answer: recapOf(absenceDeductionEnabled: false));
    expect(find.text('RETENUE'), findsNothing);
    expect(find.text('Retenue pour absences'), findsNothing);
    expect(find.text('Avec retenue'), findsNothing);
    expect(find.text('BRUT APRÈS ABSENCES'), findsOneWidget);
  });

  testWidgets('« Avec retenue » ne garde que les agents retenus', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(EteeloFilterChip, 'Avec retenue'));
    await tester.pump();

    expect(find.text('MWAMBA Clarisse'), findsOneWidget);
    expect(find.text('KALALA Didier'), findsNothing);
    expect(find.textContaining('Total ·'), findsNothing);
  });

  HrPresenceRecapCubit cubitOf(WidgetTester tester) =>
      BlocProvider.of<HrPresenceRecapCubit>(
        tester.element(find.byType(HrPresenceRecapScreen)),
      );

  testWidgets('un serveur d\'avant la paie au mois M : les heures, jamais un '
      'brut à 0', (tester) async {
    await pump(
      tester,
      answer: HrAttendanceRecapModel.fromJson(fx.recap(legacy: true)),
    );

    expect(find.text('HEURES VAC.'), findsOneWidget);
    expect(find.text('BRUT PRÉVU'), findsNothing);
    // Le montant des heures, pas un brut vide à « 0,00 ».
    expect(find.textContaining('160,00'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('0,00'),
      ),
      findsNothing,
    );
  });

  testWidgets('sans hr.pay.read : les heures, sans argent du mois', (
    tester,
  ) async {
    await pump(tester, answer: recapOf(withAmounts: false));
    expect(find.text('HEURES VAC.'), findsOneWidget);
    expect(find.text('BRUT PRÉVU'), findsNothing);
    expect(find.textContaining('Coût de la paie'), findsNothing);
  });

  testWidgets('le bandeau garde le mois et dit ce qui manque', (tester) async {
    await pump(tester, unsynced: {'a-1': 2});

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
    await pump(tester, unsynced: {'a-1': 1});

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
        "Seule la direction rouvre un mois clôturé, tant que sa paie n'est pas validée.",
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

  Finder reopenButton() => find.widgetWithText(EteeloButton, 'Rouvrir le mois');

  testWidgets('la direction rouvre un mois clos, motif à l\'appui', (
    tester,
  ) async {
    final commands = await pump(
      tester,
      permissions: [...manage, Perm.hrAttendanceReopen.wire],
      answer: recapOf(closed: true, reopenable: true),
    );
    await tester.ensureVisible(reopenButton());
    await tester.tap(reopenButton());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Justificatif reçu');
    await tester.tap(find.widgetWithText(EteeloButton, 'Rouvrir le mois').last);
    await tester.pumpAndSettle();

    verify(
      () => commands.reopenMonth('2026-10', 'Justificatif reçu'),
    ).called(1);
  });

  testWidgets('sans hr.attendance.reopen, ou si le serveur refuserait, pas '
      'de réouverture', (tester) async {
    await pump(
      tester,
      permissions: manage,
      answer: recapOf(closed: true, reopenable: true),
    );
    expect(reopenButton(), findsNothing);
  });

  testWidgets('un mois non rouvrable (paie validée) ne propose rien', (
    tester,
  ) async {
    await pump(
      tester,
      permissions: [...manage, Perm.hrAttendanceReopen.wire],
      answer: recapOf(closed: true),
    );
    expect(reopenButton(), findsNothing);
  });

  testWidgets(
    'une réouverture refusée par le serveur se dit sur le mois clos',
    (tester) async {
      await pump(
        tester,
        permissions: manage,
        answer: recapOf(closed: true),
        lock: const StaffAttendanceLock(
          kind: StaffAttendanceLockKind.month,
          periodStart: '2026-10-01',
          locked: true,
          syncState: RecordSyncState.failed,
        ),
      );
      expect(find.textContaining('refusé par le serveur'), findsOneWidget);
    },
  );

  testWidgets('une réouverture posée ici et pas encore envoyée se dit', (
    tester,
  ) async {
    await pump(
      tester,
      permissions: manage,
      answer: recapOf(closed: true),
      lock: const StaffAttendanceLock(
        kind: StaffAttendanceLockKind.month,
        periodStart: '2026-10-01',
        locked: false,
        syncState: RecordSyncState.pending,
      ),
    );
    expect(find.textContaining('Réouverture enregistrée'), findsOneWidget);
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
    expect(find.textContaining('refusé par le serveur'), findsOneWidget);
  });

  testWidgets('un mois passé non clôturable ne promet pas de date', (
    tester,
  ) async {
    await pump(tester, permissions: manage, answer: recapOf(toDate: false));
    expect(find.textContaining('Clôture possible'), findsNothing);
  });

  testAtReferenceFormats('le récapitulatif tient', (tester, format) async {
    await pump(tester, size: null, permissions: manage, unsynced: {'a-1': 3});
    expect(find.byType(HrPresenceRecapTable), findsOneWidget);
  });

  testAtReferenceFormats('un mois passé tient, avec « Mois en cours »', (
    tester,
    format,
  ) async {
    await pump(tester, size: null, permissions: manage);
    await cubitOf(tester).stepMonth(-1);
    await tester.pump();
    await tester.pump();

    expect(find.text('Mois en cours'), findsOneWidget);
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
