import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
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

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

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

  late GoRouter router;

  /// Monte l'écran. [permissions] : `null` monte sans session (la porte
  /// laisse tout passer). [location] : monté sous un routeur, à cette adresse.
  Future<StaffAttendanceCubit> pump(
    WidgetTester tester, {
    List<String>? permissions,
    String? location,
  }) async {
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
    Widget screen = BlocProvider.value(
      value: cubit..load(),
      child: const HrPresenceRegisterScreen(),
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
    final page = Scaffold(body: screen);
    if (location == null) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      );
    } else {
      router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/rh-presences/:ecran', builder: (_, _) => page),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }
    await tester.pump();
    await tester.pump();
    return cubit;
  }

  String address() => router.routerDelegate.currentConfiguration.uri.toString();

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

  group('l\'adresse', () {
    testWidgets('un lien rouvre son jour, sa vue et ses filtres', (
      tester,
    ) async {
      final cubit = await pump(
        tester,
        location:
            '/rh-presences/registre?jour=2026-09-25&vue=list'
            '&categorie=teacher&statut=none',
      );
      await tester.pumpAndSettle();

      expect(cubit.state.day, '2026-09-25');
      expect(cubit.state.viewMode, CollectionViewMode.list);
      expect(cubit.state.dayQuery.category, StaffCategory.teacher);
      expect(cubit.state.dayQuery.status, PresenceStatus.none);
    });

    testWidgets('changer de jour s\'inscrit ; « Aujourd\'hui » rend '
        'l\'adresse nue', (tester) async {
      await pump(tester, location: '/rh-presences/registre');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      expect(address(), '/rh-presences/registre?jour=2026-09-28');

      await tester.tap(find.text('Aujourd\'hui'));
      await tester.pumpAndSettle();
      expect(address(), '/rh-presences/registre');
    });

    testWidgets('un samedi recule au vendredi ; un jour illisible ou à venir '
        'garde le dernier jour ouvré', (tester) async {
      final cubit = await pump(
        tester,
        location: '/rh-presences/registre?jour=2026-09-26',
      );
      await tester.pumpAndSettle();
      expect(cubit.state.day, '2026-09-25');

      router.go('/rh-presences/registre?jour=2026-02-30');
      await tester.pumpAndSettle();
      expect(cubit.state.day, '2026-09-29');

      router.go('/rh-presences/registre?jour=2026-10-05');
      await tester.pumpAndSettle();
      expect(cubit.state.day, '2026-09-29');
    });

    testWidgets('un jour d\'avant l\'année scolaire revient au dernier jour '
        'ouvré', (tester) async {
      final cubit = await pump(
        tester,
        location: '/rh-presences/registre?jour=2026-08-28',
      );
      await tester.pumpAndSettle();
      expect(cubit.state.day, '2026-09-29');
    });
  });

  group('les réglages (E2)', () {
    testWidgets('sans hr.attendance.manage, l\'horaire se lit sans s\'ouvrir', (
      tester,
    ) async {
      await pump(
        tester,
        permissions: [Perm.hrAttendanceRead.wire, Perm.hrAttendanceWrite.wire],
      );

      final inBanner = find.descendant(
        of: find.byType(PresenceDayBanner),
        matching: find.byIcon(Icons.schedule),
      );
      expect(inBanner, findsOneWidget);
      expect(find.byIcon(Icons.tune), findsNothing);
      await tester.tap(find.textContaining('tolérance'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('la direction ouvre les réglages', (tester) async {
      await pump(
        tester,
        permissions: [
          Perm.hrAttendanceRead.wire,
          Perm.hrAttendanceWrite.wire,
          Perm.hrAttendanceManage.wire,
        ],
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
      await tester.tap(find.textContaining('tolérance'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  testWidgets('les flèches du jour offrent 48 dp au doigt', (tester) async {
    await pump(tester);

    for (final button in tester.widgetList(find.byType(PresenceBannerButton))) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(find.byType(PresenceBannerButton), findsWidgets);
  });
}
