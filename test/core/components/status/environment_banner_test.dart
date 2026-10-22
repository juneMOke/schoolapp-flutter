import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/environment_banner.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pumpBanner(WidgetTester tester, EnvConfig config) {
    return tester.pumpWidget(
      MaterialApp(
        // Sinon le bandeau « DEBUG » de Flutter compte comme un second Banner.
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: EnvironmentBanner(config: config, child: const SizedBox()),
      ),
    );
  }

  EnvConfig configFor(String env, {bool? show}) => EnvConfig.forTesting(
    appEnvironment: env,
    apiBaseUrl: 'https://api.example.com',
    showEnvironmentBanner: show,
  );

  testWidgets('dev : badge « DEV » vert savane', (tester) async {
    await pumpBanner(tester, configFor('dev', show: null));

    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'DEV');
    expect(banner.color, AppColors.vertSavane);
  });

  testWidgets('staging : badge « STG » terre cuite', (tester) async {
    await pumpBanner(tester, configFor('staging', show: null));

    final banner = tester.widget<Banner>(find.byType(Banner));
    expect(banner.message, 'STG');
    expect(banner.color, AppColors.terreCuiteDark);
  });

  testWidgets('prod : aucun badge par défaut', (tester) async {
    await pumpBanner(tester, configFor('prod', show: null));

    expect(find.byType(Banner), findsNothing);
  });

  testWidgets('le define explicite prime sur le défaut', (tester) async {
    await pumpBanner(tester, configFor('dev', show: false));
    expect(find.byType(Banner), findsNothing);

    await pumpBanner(tester, configFor('prod', show: true));
    expect(tester.widget<Banner>(find.byType(Banner)).message, 'PROD');
  });
}
