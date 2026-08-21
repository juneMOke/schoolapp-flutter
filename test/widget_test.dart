import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/components/status/sync_lifecycle_observer.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/main.dart';
import 'core/offline/offline_full_test_db.dart';
import 'test_helpers/widget_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await installCommonTestPluginMocks();
    await configureDependencies(
      envConfig: EnvConfig.forTesting(
        appEnvironment: AppEnvironment.dev.label,
        apiBaseUrl: 'http://127.0.0.1:8080',
      ),
      // `noIsolate` : sous `testWidgets` (FakeAsync), une requête servie par
      // l'isolat ffi ne revient jamais — cf. `openFullOfflineDb`.
      offlineDatabase: await openFullOfflineDb(noIsolate: true),
    );
  });

  tearDownAll(() async {
    await removeCommonTestPluginMocks();
    await getIt.reset();
  });

  testWidgets('App smoke test - renders without error', (
    WidgetTester tester,
  ) async {
    await pumpBounded(
      tester,
      const MyApp(),
      frames: 2,
      step: const Duration(milliseconds: 150),
    );
    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('App wires the resume trigger of the sync loop', (
    WidgetTester tester,
  ) async {
    // Troisième déclencheur global (les deux autres : ouverture de session,
    // retour réseau). Sa politique est testée dans `SyncStatusCubit` et son
    // câblage au cycle de vie dans `SyncLifecycleObserver` — reste ce qu'aucun des
    // deux ne voit : que la racine le monte réellement. Un déclencheur de
    // synchro non branché n'apparaît sur aucun écran et ne fait échouer aucun
    // test métier.
    await pumpBounded(
      tester,
      const MyApp(),
      frames: 2,
      step: const Duration(milliseconds: 150),
    );

    expect(find.byType(SyncLifecycleObserver), findsOneWidget);

    // Monté ne suffit pas : ses rappels doivent atteindre le cubit que la
    // racine fournit à l'arbre. Remplacer l'un d'eux par un no-op laissait
    // jusqu'ici toute la suite verte — le battement continuait de tourner en
    // arrière-plan, ou après une déconnexion, sans qu'aucun test ne bronche.
    final element = tester.element(find.byType(SyncLifecycleObserver));
    final observer = tester.widget<SyncLifecycleObserver>(
      find.byType(SyncLifecycleObserver),
    );
    final cubit = element.read<SyncStatusCubit>();
    addTearDown(cubit.onSessionClosed);

    cubit.onSessionOpened();
    expect(cubit.isHeartbeatActive, isTrue);

    observer.onPause();
    expect(
      cubit.isHeartbeatActive,
      isFalse,
      reason: 'onPause doit atteindre onBackground du cubit fourni',
    );

    observer.onResume();
    expect(
      cubit.isHeartbeatActive,
      isTrue,
      reason: 'onResume doit atteindre onForeground du cubit fourni',
    );
  });

  testWidgets('Login layout stays stable on narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpBounded(
      tester,
      const MyApp(),
      frames: 2,
      step: const Duration(milliseconds: 150),
    );

    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login layout stays stable on desktop with low height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 420));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpBounded(
      tester,
      const MyApp(),
      frames: 2,
      step: const Duration(milliseconds: 150),
    );

    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
