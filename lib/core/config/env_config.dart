import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

class EnvConfig {
  final AppEnvironment environment;
  final Uri apiBaseUri;
  final bool showEnvironmentBanner;
  final bool enableVerboseNetworkLogging;

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUri,
    required this.showEnvironmentBanner,
    required this.enableVerboseNetworkLogging,
  });

  factory EnvConfig.fromDartDefines() {
    const rawEnvironment = String.fromEnvironment(
      AppConstants.appEnvironmentDefineKey,
      defaultValue: AppConstants.defaultAppEnvironment,
    );
    const rawApiBaseUrl = String.fromEnvironment(
      AppConstants.apiBaseUrlDefineKey,
    );
    const rawShowEnvironmentBanner = String.fromEnvironment(
      AppConstants.showEnvironmentBannerDefineKey,
      defaultValue: 'false',
    );
    const rawVerboseNetworkLogging = String.fromEnvironment(
      AppConstants.enableVerboseNetworkLoggingDefineKey,
      defaultValue: 'false',
    );

    return EnvConfig._fromValues(
      appEnvironment: rawEnvironment,
      apiBaseUrl: rawApiBaseUrl,
      showEnvironmentBanner: rawShowEnvironmentBanner,
      enableVerboseNetworkLogging: rawVerboseNetworkLogging,
    );
  }

  factory EnvConfig.forTesting({
    required String appEnvironment,
    required String apiBaseUrl,
    bool showEnvironmentBanner = false,
    bool enableVerboseNetworkLogging = false,
  }) {
    return EnvConfig._fromValues(
      appEnvironment: appEnvironment,
      apiBaseUrl: apiBaseUrl,
      showEnvironmentBanner: showEnvironmentBanner.toString(),
      enableVerboseNetworkLogging: enableVerboseNetworkLogging.toString(),
    );
  }

  factory EnvConfig._fromValues({
    required String appEnvironment,
    required String apiBaseUrl,
    required String showEnvironmentBanner,
    required String enableVerboseNetworkLogging,
  }) {
    final environment = AppEnvironment.fromName(appEnvironment);
    final normalizedBaseUrl = apiBaseUrl.trim();

    if (normalizedBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL est obligatoire. Passez --dart-define=API_BASE_URL=... ',
      );
    }

    final parsedUri = Uri.tryParse(normalizedBaseUrl);
    if (parsedUri == null || !parsedUri.hasScheme || parsedUri.host.isEmpty) {
      throw StateError(
        'API_BASE_URL doit être une URL absolue valide. Valeur reçue: $apiBaseUrl',
      );
    }

    return EnvConfig._(
      environment: environment,
      apiBaseUri: parsedUri,
      showEnvironmentBanner: _parseBool(showEnvironmentBanner),
      enableVerboseNetworkLogging: _parseBool(enableVerboseNetworkLogging),
    );
  }

  String get apiBaseUrl => apiBaseUri.toString();
  String get environmentLabel => environment.label;
  String get environmentDisplayName => environment.displayName;
  bool get isDevelopment => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.prod;

  static bool _parseBool(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
        return false;
    }

    throw StateError(
      'Valeur booléenne invalide: $rawValue',
    );
  }
}
