import 'package:school_app_flutter/core/web/splash_loader_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/splash_loader_web.dart'
    as impl;

/// Retire le pré-splash HTML (couche W) une fois le premier frame Flutter peint.
///
/// Web uniquement : appelle la fonction JS `removeSplashLoader` définie dans
/// `web/index.html`. No-op sur mobile/desktop (cf. import conditionnel).
void removeWebSplashLoader() => impl.removeWebSplashLoader();
