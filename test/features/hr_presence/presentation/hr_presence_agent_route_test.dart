import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/usecases/hr_attendance_stats_use_cases.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_args.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_agent_page.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/pages/hr_presence_fiche_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/hr_agent_routes.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';

import '../hr_presence_builders.dart';

class _MockGet extends Mock implements GetHrAttendanceAgentMonthUseCase {}

class _MockSource extends Mock implements StaffSnapshotSource {}

class _MockYear extends Mock implements GetHrAttendanceAgentYearUseCase {}

/// Le détail d'un agent a son adresse sous le tableau de bord :
/// `/home/rh-presences-tableau-de-bord/{agentId}?mois=AAAA-MM`.
void main() {
  final getIt = GetIt.instance;
  late _MockGet get;
  late _MockYear year;
  const dashboard = MenuConstants.hrPresenceDashboardId;

  setUp(() {
    get = _MockGet();
    final source = _MockSource();
    when(
      () => source.read(),
    ).thenAnswer((_) async => const Left(StorageFailure('—')));
    when(
      () => get(any(), month: any(named: 'month')),
    ).thenAnswer((_) async => Right(agentMonthOf()));
    getIt.registerFactoryParam<
      HrPresenceAgentMonthCubit,
      HrPresenceAgentArgs,
      void
    >(
      (args, _) => HrPresenceAgentMonthCubit(
        getMonth: get,
        source: source,
        agentId: args.agentId,
        month: args.month,
        yearStart: args.yearStart,
        now: () => DateTime(2026, 10, 23, 10),
      ),
    );
    year = _MockYear();
    when(() => year(any())).thenAnswer((_) async => Right(agentYearOf()));
    getIt.registerFactoryParam<HrPresenceFicheCubit, HrPresenceFicheArgs, void>(
      (args, _) => HrPresenceFicheCubit(
        getMonth: get,
        getYear: year,
        source: source,
        args: args,
        now: () => DateTime(2026, 10, 23, 10),
      ),
    );
  });
  tearDown(() async => getIt.reset());

  var closed = 0;

  Future<GoRouter> pump(WidgetTester tester, String location) async {
    closed = 0;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1400);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: AppRoutesNames.homeSubMenuRoute,
          pageBuilder: (_, state) => MaterialPage<void>(
            key: const ValueKey('home-shell'),
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => HrPresenceAgentPage.open(
                    context,
                    agentId: 'a-1',
                    month: '2026-09',
                  ).then((_) => closed++),
                  child: Text('écran ${state.pathParameters['subMenuId']}'),
                ),
              ),
            ),
          ),
          routes: [HrAgentRoutes.agent()],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ReflectedRecordsParser.configOf(router),
      ),
    );
    await tester.pump();
    await tester.pump();
    return router;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('ouvert depuis le tableau de bord : son mois, son adresse', (
    tester,
  ) async {
    final router = await pump(tester, '/home/$dashboard');
    await tester.tap(find.text('écran $dashboard'));
    await settle(tester);

    expect(find.byType(HrPresenceAgentScreen), findsOneWidget);
    verify(() => get('a-1', month: '2026-09')).called(1);
    expect(
      ReflectedRecordsParser.reflectedUri(
        router.routerDelegate.currentConfiguration,
      ).toString(),
      '/home/$dashboard/a-1?mois-agent=2026-09',
    );

    await tester.tap(find.byTooltip('Tous les agents'));
    await settle(tester);
    expect(find.byType(HrPresenceAgentScreen), findsNothing);
    expect(closed, 1);
  });

  testWidgets('rechargé : le tableau de bord dessous, le même mois', (
    tester,
  ) async {
    await pump(tester, '/home/$dashboard/a-1?mois-agent=2026-09');
    await settle(tester);

    expect(find.byType(HrPresenceAgentScreen), findsOneWidget);
    verify(() => get('a-1', month: '2026-09')).called(1);
  });

  testWidgets(
    'la fiche individuelle a son adresse : `?vue-agent=an` l\'ouvre sur '
    'l\'année',
    (tester) async {
      await pump(
        tester,
        '/home/${MenuConstants.hrPresenceFicheId}/a-1?vue-agent=an',
      );
      await settle(tester);

      expect(find.byType(HrPresenceFicheAgentScreen), findsOneWidget);
      verify(() => year('a-1')).called(1);
    },
  );

  testWidgets('rechargé puis refermé : les clés de l\'agent quittent '
      'l\'adresse du tableau de bord', (tester) async {
    final router = await pump(
      tester,
      '/home/$dashboard/a-1?mois-agent=2026-09',
    );
    await settle(tester);
    await tester.tap(find.byTooltip('Tous les agents'));
    await settle(tester);

    expect(find.byType(HrPresenceAgentScreen), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home/$dashboard',
    );
  });

  testWidgets('ouverte depuis le récapitulatif, la fiche lui appartient', (
    tester,
  ) async {
    await pump(
      tester,
      '/home/${MenuConstants.hrPresenceRecapId}/a-1?mois-agent=2026-09',
    );
    await settle(tester);

    expect(find.byType(HrPresenceFicheAgentScreen), findsOneWidget);
    expect(find.byTooltip('Récapitulatif'), findsOneWidget);
  });
}
