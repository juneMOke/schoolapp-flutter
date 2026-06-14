// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $LibGen {
  const $LibGen();

  /// Directory path: lib/features
  $LibFeaturesGen get features => const $LibFeaturesGen();
}

class $AssetsBrandingGen {
  const $AssetsBrandingGen();

  /// Directory path: assets/branding/clair
  $AssetsBrandingClairGen get clair => const $AssetsBrandingClairGen();

  /// Directory path: assets/branding/fonce
  $AssetsBrandingFonceGen get fonce => const $AssetsBrandingFonceGen();

  /// Directory path: assets/branding/profond
  $AssetsBrandingProfondGen get profond => const $AssetsBrandingProfondGen();

  /// Directory path: assets/branding/splash
  $AssetsBrandingSplashGen get splash => const $AssetsBrandingSplashGen();
}

class $AssetsCatalogsGen {
  const $AssetsCatalogsGen();

  /// File path: assets/catalogs/address_geo_catalog.json
  String get addressGeoCatalog => 'assets/catalogs/address_geo_catalog.json';

  /// File path: assets/catalogs/education_cycles_catalog.json
  String get educationCyclesCatalog =>
      'assets/catalogs/education_cycles_catalog.json';

  /// List of all assets
  List<String> get values => [addressGeoCatalog, educationCyclesCatalog];
}

class $AssetsPatternsGen {
  const $AssetsPatternsGen();

  /// File path: assets/patterns/kuba_tile.svg
  String get kubaTile => 'assets/patterns/kuba_tile.svg';

  /// List of all assets
  List<String> get values => [kubaTile];
}

class $LibFeaturesGen {
  const $LibFeaturesGen();

  /// Directory path: lib/features/auth
  $LibFeaturesAuthGen get auth => const $LibFeaturesAuthGen();
}

class $AssetsBrandingClairGen {
  const $AssetsBrandingClairGen();

  /// File path: assets/branding/clair/logo_horizontal_couleur.svg
  String get logoHorizontalCouleur =>
      'assets/branding/clair/logo_horizontal_couleur.svg';

  /// File path: assets/branding/clair/symbole_couleur.svg
  String get symboleCouleur => 'assets/branding/clair/symbole_couleur.svg';

  /// List of all assets
  List<String> get values => [logoHorizontalCouleur, symboleCouleur];
}

class $AssetsBrandingFonceGen {
  const $AssetsBrandingFonceGen();

  /// File path: assets/branding/fonce/logo_horizontal_fond_fonce.svg
  String get logoHorizontalFondFonce =>
      'assets/branding/fonce/logo_horizontal_fond_fonce.svg';

  /// File path: assets/branding/fonce/symbole_fond_fonce.svg
  String get symboleFondFonce => 'assets/branding/fonce/symbole_fond_fonce.svg';

  /// List of all assets
  List<String> get values => [logoHorizontalFondFonce, symboleFondFonce];
}

class $AssetsBrandingProfondGen {
  const $AssetsBrandingProfondGen();

  /// File path: assets/branding/profond/logo_horizontal_couleur.svg
  String get logoHorizontalCouleur =>
      'assets/branding/profond/logo_horizontal_couleur.svg';

  /// File path: assets/branding/profond/symbole_monochrome.svg
  String get symboleMonochrome =>
      'assets/branding/profond/symbole_monochrome.svg';

  /// File path: assets/branding/profond/symbole_silhouette_blanche.svg
  String get symboleSilhouetteBlanche =>
      'assets/branding/profond/symbole_silhouette_blanche.svg';

  /// List of all assets
  List<String> get values => [
    logoHorizontalCouleur,
    symboleMonochrome,
    symboleSilhouetteBlanche,
  ];
}

class $AssetsBrandingSplashGen {
  const $AssetsBrandingSplashGen();

  /// File path: assets/branding/splash/ic_launcher_xxxhdpi_192px_transparent.png
  AssetGenImage get icLauncherXxxhdpi192pxTransparent => const AssetGenImage(
    'assets/branding/splash/ic_launcher_xxxhdpi_192px_transparent.png',
  );

  /// File path: assets/branding/splash/splash_logo_2048.png
  AssetGenImage get splashLogo2048 =>
      const AssetGenImage('assets/branding/splash/splash_logo_2048.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    icLauncherXxxhdpi192pxTransparent,
    splashLogo2048,
  ];
}

class $LibFeaturesAuthGen {
  const $LibFeaturesAuthGen();

  /// Directory path: lib/features/auth/data
  $LibFeaturesAuthDataGen get data => const $LibFeaturesAuthDataGen();
}

class $LibFeaturesAuthDataGen {
  const $LibFeaturesAuthDataGen();

  /// Directory path: lib/features/auth/data/datasources
  $LibFeaturesAuthDataDatasourcesGen get datasources =>
      const $LibFeaturesAuthDataDatasourcesGen();
}

class $LibFeaturesAuthDataDatasourcesGen {
  const $LibFeaturesAuthDataDatasourcesGen();

  /// File path: lib/features/auth/data/datasources/auth_local_data_source.dart
  String get authLocalDataSource =>
      'lib/features/auth/data/datasources/auth_local_data_source.dart';

  /// File path: lib/features/auth/data/datasources/auth_remote_data_source.dart
  String get authRemoteDataSource =>
      'lib/features/auth/data/datasources/auth_remote_data_source.dart';

  /// File path: lib/features/auth/data/datasources/forgot_password_remote_data_source.dart
  String get forgotPasswordRemoteDataSource =>
      'lib/features/auth/data/datasources/forgot_password_remote_data_source.dart';

  /// List of all assets
  List<String> get values => [
    authLocalDataSource,
    authRemoteDataSource,
    forgotPasswordRemoteDataSource,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsBrandingGen branding = $AssetsBrandingGen();
  static const $AssetsCatalogsGen catalogs = $AssetsCatalogsGen();
  static const $AssetsPatternsGen patterns = $AssetsPatternsGen();
  static const $LibGen lib = $LibGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
