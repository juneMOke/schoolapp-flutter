import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/main.dart';
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
      bootstrapBoxName: 'bootstrap_box_widget_test',
    );
  });

  tearDownAll(() async {
    await removeCommonTestPluginMocks();
    await getIt.reset();
  });

  testWidgets('App smoke test - renders without error', (
    WidgetTester tester,
  ) async {
    await pumpBounded(tester, const MyApp(), frames: 2, step: const Duration(milliseconds: 150));
    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login layout stays stable on narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpBounded(tester, const MyApp(), frames: 2, step: const Duration(milliseconds: 150));

    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login layout stays stable on desktop with low height', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 420));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpBounded(tester, const MyApp(), frames: 2, step: const Duration(milliseconds: 150));

    expect(find.byType(MyApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}