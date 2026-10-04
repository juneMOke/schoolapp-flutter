import 'package:school_app_flutter/core/web/unload_guard_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/unload_guard_web.dart'
    as impl;

/// Fait demander confirmation au navigateur avant de fermer ou de recharger
/// l'onglet, tant que [active] — c'est-à-dire tant qu'un envoi attend dans
/// l'outbox. No-op hors du web (cf. import conditionnel).
void setUnloadGuard(bool active) => impl.setUnloadGuard(active);
