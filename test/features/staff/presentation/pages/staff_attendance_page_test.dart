import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_page_section.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_results_bar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_bulk_mark_button.dart';
import 'package:school_app_flutter/core/navigation/route_exit_guard.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_count_row.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_report_dialog.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_status_segment.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_validated_banner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_attendance_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_commands.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_attendance_page.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_time_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_row.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_tabs.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_banners.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff_builders.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

class _MockLoad extends Mock implements LoadStaffAttendanceUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

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
              status: PresenceStatus.late,
              arrival: ClockTime.tryParse('07:52'),
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
        schoolYear: const SchoolYearBounds(start: '2026-09-01'),
        hasEverSynced: true,
      );

  Future<StaffAttendanceCubit> pump(
    WidgetTester tester, {
    bool validated = false,
    Size size = const Size(1280, 1000),
    List<String>? permissions,
    DateTime? now,
    CollectionViewMode? view,
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
      now: () => now ?? DateTime(2026, 9, 29, 7, 35),
    );
    if (view != null) cubit.setViewMode(view);
    Widget screen = BlocProvider.value(
      value: cubit..load(),
      child: const StaffAttendanceScreen(),
    );
    if (permissions != null) {
      final auth = _MockAuthBloc();
      final state = AuthState(
        status: AuthStatus.authenticated,
        permissions: permissions,
      );
      when(() => auth.state).thenReturn(state);
      whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
      screen = BlocProvider<AuthBloc>.value(value: auth, child: screen);
    }
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: screen),
      ),
    );
    await tester.pump();
    await tester.pump();
    return cubit;
  }

  testWidgets('le registre s\'ouvre en liste, comme les autres tables', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(StaffAttendanceRow), findsNWidgets(2));
    expect(find.byType(StaffAttendanceCard), findsNothing);
  });

  testWidgets('le registre montre une carte par agent et les onglets', (
    tester,
  ) async {
    await pump(tester, view: CollectionViewMode.grid);

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
    await pump(tester, view: CollectionViewMode.grid);

    await tester.tap(find.text('Kalala Mutombo'));
    await tester.pump();

    final records =
        verify(() => save(captureAny())).captured.single
            as List<StaffAttendanceRecord>;
    expect(records.single.staffMemberId, 'm-1');
    expect(records.single.status, PresenceStatus.present);
    expect(records.single.arrival, ClockTime.tryParse('07:35'));
  });

  testWidgets('la liste donne un segment de statut par agent', (tester) async {
    await pump(tester, view: CollectionViewMode.grid);

    await tester.tap(find.text('Liste'));
    await tester.pump();

    expect(find.byType(StaffAttendanceRow), findsNWidgets(2));
  });

  testWidgets('un jour validé montre le bandeau et refuse les gestes', (
    tester,
  ) async {
    await pump(tester, validated: true, view: CollectionViewMode.grid);

    expect(find.byType(StaffValidatedBanner), findsOneWidget);
    // La tête de fiche : badge « Validé » et les compteurs de la modale.
    final banner = find.byType(PresenceValidatedBanner);
    expect(
      find.descendant(of: banner, matching: find.text('Validé')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: banner, matching: find.byType(PresenceCountRow)),
      findsOneWidget,
    );
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

  testWidgets('un jour validé refuse aussi les gestes de la liste', (
    tester,
  ) async {
    await pump(tester, validated: true);

    await tester.tap(
      find.descendant(
        of: find.byType(PresenceStatusSegment).first,
        matching: find.text('Absent'),
      ),
    );
    await tester.pump();

    verifyNever(() => save(any()));
  });

  testWidgets(
    '« Voir dans le registre » lève la recherche et filtre sur les non '
    'pointés',
    (tester) async {
      final cubit = await pump(tester);
      cubit.setDayText('Mayala');
      await tester.pump();

      await tester.tap(find.text('Valider le rapport'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir dans le registre'));
      await tester.pumpAndSettle();

      expect(cubit.state.dayQuery.text, isEmpty);
      expect(cubit.state.dayQuery.status, PresenceStatus.none);
    },
  );

  testWidgets('deux sections sur un fin fond ; la barre de résultats porte '
      'le compte et le pointage en masse', (tester) async {
    await pump(tester);

    expect(find.byType(EteeloPageSection), findsNWidgets(2));
    final bar = find.byType(EteeloResultsBar);
    expect(
      find.descendant(of: bar, matching: find.text('2 agents · 1 à pointer')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(PresenceBulkMarkButton)),
      findsOneWidget,
    );
  });

  group('pointer les non pointés en une fois', () {
    testWidgets('« Présents à l\'heure » pointe les seuls non pointés', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Pointer 1 non-pointé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Présents à l\'heure'));
      await tester.pumpAndSettle();

      final records =
          verify(() => save(captureAny())).captured.single
              as List<StaffAttendanceRecord>;
      expect(records.single.staffMemberId, 'm-1');
      expect(records.single.status, PresenceStatus.present);
    });

    testWidgets('« Absents » demande confirmation', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Pointer 1 non-pointé'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Absents'));
      await tester.pumpAndSettle();
      expect(find.text('Marquer 1 personne absente ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      verifyNever(() => save(any()));

      await tester.tap(find.text('Pointer 1 non-pointé'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Absents'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Marquer absents'));
      await tester.pumpAndSettle();

      final records =
          verify(() => save(captureAny())).captured.single
              as List<StaffAttendanceRecord>;
      expect(records.single.status, PresenceStatus.absent);
    });

    testWidgets('la recherche réduit la portée', (tester) async {
      final cubit = await pump(tester);
      cubit.setDayText('Mayala');
      await tester.pumpAndSettle();
      expect(find.text('Pointer 1 non-pointé'), findsNothing);
    });

    testWidgets('un jour validé ne propose rien', (tester) async {
      await pump(tester, validated: true);
      expect(find.text('Pointer 1 non-pointé'), findsNothing);
    });
  });

  group('quitter un jour pointé mais pas validé', () {
    const title = 'Le rapport du mardi 29 septembre 2026 n\'est pas validé';

    /// Monte l'écran et pointe un agent : le jour devient « touché ».
    Future<StaffAttendanceCubit> pumpEdited(WidgetTester tester) async {
      final cubit = await pump(tester, view: CollectionViewMode.grid);
      await tester.tap(find.text('Kalala Mutombo'));
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('changer de jour pose la question ; « Rester » garde le jour', (
      tester,
    ) async {
      final cubit = await pumpEdited(tester);

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);

      await tester.tap(find.text('Rester'));
      await tester.pumpAndSettle();
      expect(cubit.state.day, _day);
    });

    testWidgets('« Valider et quitter » ouvre la validation ; l\'annuler '
        'garde le jour', (tester) async {
      final cubit = await pumpEdited(tester);

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider et quitter'));
      await tester.pumpAndSettle();
      expect(find.byType(PresenceReportDialog), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(cubit.state.day, _day);
    });

    testWidgets('« Quitter sans valider » change de jour', (tester) async {
      final cubit = await pumpEdited(tester);

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter sans valider'));
      await tester.pumpAndSettle();

      expect(cubit.state.day, '2026-09-28');
    });

    testWidgets('quitter l\'écran pose la même question, même depuis un autre '
        'onglet', (tester) async {
      await pumpEdited(tester);
      await tester.tap(find.text('Récapitulatif du mois'));
      await tester.pumpAndSettle();

      final leaving = RouteExitGuard.mayLeave(
        tester.element(find.byType(StaffAttendanceTabs)),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);

      await tester.tap(find.text('Quitter sans valider'));
      await tester.pumpAndSettle();
      expect(await leaving, isTrue);
    });

    testWidgets('un jour seulement consulté part sans question', (
      tester,
    ) async {
      // Des pointages d'un autre poste, aucun geste ici : rien à rappeler.
      final cubit = await pump(tester);

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(cubit.state.day, '2026-09-28');
    });

    testWidgets('un jour validé part sans question', (tester) async {
      final cubit = await pump(tester, validated: true);

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(cubit.state.day, '2026-09-28');
    });

    testWidgets('en lecture seule, un geste refusé ne garde rien', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        permissions: [Perm.hrAttendanceRead.wire],
        view: CollectionViewMode.grid,
      );
      await tester.tap(find.text('Kalala Mutombo'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(cubit.state.day, '2026-09-28');
    });
  });

  testWidgets('le récapitulatif ouvre la fiche d\'un agent', (tester) async {
    final cubit = await pump(tester);

    await tester.tap(find.text('Récapitulatif du mois'));
    await tester.pump();
    await tester.tap(find.text('Mayala Mutombo Ruth'));
    await tester.pump();

    expect(cubit.state.agentId, 'm-2');
    expect(find.text('Retards et absences du mois'), findsOneWidget);
  });

  testWidgets('en lecture seule, toucher une carte ne met rien en file', (
    tester,
  ) async {
    await pump(
      tester,
      permissions: [Perm.hrAttendanceRead.wire],
      view: CollectionViewMode.grid,
    );

    await tester.tap(find.text('Kalala Mutombo'));
    await tester.pump();

    verifyNever(() => save(any()));
    expect(
      find.text(
        'Seuls la direction et le préfet ou le censeur (compte '
        'administration académique) pointent le personnel.',
      ),
      findsOneWidget,
    );
    expect(find.text('Valider le rapport'), findsNothing);
  });

  testWidgets('clore : un mois révolu, et seulement avec `manage`', (
    tester,
  ) async {
    Future<void> openPreviousRecap(List<String> permissions) async {
      final cubit = await pump(
        tester,
        permissions: permissions,
        now: DateTime(2026, 10, 1, 9),
      );
      await tester.tap(find.text('Récapitulatif du mois'));
      await tester.pump();
      await cubit.stepMonth(-1);
      await tester.pump();
    }

    await openPreviousRecap([
      Perm.hrAttendanceRead.wire,
      Perm.hrAttendanceWrite.wire,
    ]);
    expect(find.text('Clôturer le mois'), findsNothing);

    await openPreviousRecap([
      Perm.hrAttendanceRead.wire,
      Perm.hrAttendanceManage.wire,
    ]);
    expect(find.text('Clôturer le mois'), findsOneWidget);
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

    expect(find.byType(PresenceTimeDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
