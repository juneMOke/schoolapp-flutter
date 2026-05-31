enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment fromName(String value) {
    switch (value.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
    }

    throw StateError(
      'APP_ENV doit valoir dev, staging ou prod. Valeur reçue: $value',
    );
  }

  String get label => switch (this) {
    AppEnvironment.dev => 'dev',
    AppEnvironment.staging => 'staging',
    AppEnvironment.prod => 'prod',
  };

  String get displayName => switch (this) {
    AppEnvironment.dev => 'Development',
    AppEnvironment.staging => 'Staging',
    AppEnvironment.prod => 'Production',
  };
}
