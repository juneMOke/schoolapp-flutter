import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/router/hr_agent_routes.dart';
import 'package:school_app_flutter/router/reflected_records_parser.dart';

import '../../../staff/presentation/pages/staff_agent_harness.dart';
import '../../hr_personnel_builders.dart';
import '../hr_personnel_harness.dart';

/// La fiche d'un agent a son adresse, `/home/{sousMenu}/{agentId}` : la liste
/// l'ouvre par-dessus elle, et une adresse rechargée la rouvre sur la
/// coquille, l'agent relu dans le fichier local.
void main() {
  final getIt = GetIt.instance;
  late MockStaffSnapshotSource source;
  const file = MenuConstants.hrPersonnelFileId;
  final agentA = agent(
    'a',
    lastName: 'Mayala',
    contracts: [period(StaffContractKind.vacataire)],
  );

  setUpAll(StaffAgentHarness.registerFallbacks);
  setUp(() {
    StaffAgentHarness().register(getIt);
    source = MockStaffSnapshotSource();
    when(() => source.pull()).thenAnswer((_) async {});
    when(
      () => source.read(),
    ).thenAnswer((_) async => Right(snapshotOf([agentA])));
    getIt.registerFactory<StaffSnapshotSource>(() => source);
  });
  tearDown(() async => getIt.reset());

  /// La coquille remplacée par une liste qui ouvre l'agent `a` comme le
  /// Fichier : `push` avec son intent.
  Future<GoRouter> pump(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
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
                  onPressed: () => HrAgentIntent.open(
                    context,
                    subMenuId: file,
                    row: StaffFileView.build(
                      snapshotOf([agentA]),
                      query: StaffFileQuery.none,
                      today: '2026-10-24',
                      documentsVisible: true,
                    ).all.single,
                    others: [agentA],
                    today: '2026-10-24',
                  ),
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

  Finder agentPage(String id) =>
      find.byWidgetPredicate((w) => w is StaffAgentPage && w.member?.id == id);

  testWidgets('ouverte depuis la liste : aussitôt, sans relire, avec son '
      'adresse', (tester) async {
    await pump(tester, '/home/$file');
    await tester.tap(find.text('écran $file'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(agentPage('a'), findsOneWidget);
    verifyNever(() => source.read());
    final reflected = ReflectedRecordsParser(
      GoRouter.of(tester.element(agentPage('a'))).routeInformationParser,
    );
    final router = GoRouter.of(tester.element(agentPage('a')));
    expect(
      reflected
          .restoreRouteInformation(router.routerDelegate.currentConfiguration)
          ?.uri
          .path,
      '/home/$file/a',
    );
  });

  testWidgets('rechargée : la coquille dessous, l\'agent relu avec son '
      'contrat du jour', (tester) async {
    final router = await pump(tester, '/home/$file/a');

    final page = tester.widget<StaffAgentPage>(agentPage('a'));
    expect(page.kind, StaffContractKind.vacataire);
    expect(page.others.map((m) => m.id), ['a']);
    verifyNever(() => source.pull());

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('écran $file'), findsOneWidget);
  });

  testWidgets('un agent absent fait tirer une fois, puis se dit introuvable '
      '; le bouton rend l\'écran', (tester) async {
    await pump(tester, '/home/$file/inconnu');
    await tester.pump();

    verify(() => source.pull()).called(1);
    verify(() => source.read()).called(2);
    expect(find.text('Agent introuvable'), findsOneWidget);

    await tester.tap(find.text('Retour au personnel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('écran $file'), findsOneWidget);
  });

  testWidgets('tiré, l\'agent arrivé s\'ouvre', (tester) async {
    var pulled = false;
    when(() => source.pull()).thenAnswer((_) async => pulled = true);
    when(
      () => source.read(),
    ).thenAnswer((_) async => Right(snapshotOf(pulled ? [agentA] : const [])));
    await pump(tester, '/home/$file/a');
    await tester.pump();

    expect(agentPage('a'), findsOneWidget);
  });

  testWidgets('une base illisible est une panne, pas un agent introuvable', (
    tester,
  ) async {
    when(() => source.read()).thenAnswer(
      (_) async =>
          const Left<Failure, StaffFileSnapshot>(StorageFailure('illisible')),
    );
    await pump(tester, '/home/$file/a');

    expect(find.byType(StaffResultsErrorState), findsOneWidget);
    verifyNever(() => source.pull());
  });

  testWidgets('sous un autre écran, l\'adresse retombe sur l\'écran', (
    tester,
  ) async {
    final router = await pump(tester, '/home/facturations/a');

    expect(find.text('écran facturations'), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/home/facturations',
    );
  });
}
