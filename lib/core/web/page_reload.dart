import 'package:school_app_flutter/core/web/page_reload_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/page_reload_web.dart'
    as impl;

/// Recharge la page — sur le web, charge la version déployée. No-op ailleurs
/// (cf. import conditionnel). Une saisie gardée (`beforeunload`) fait encore
/// demander le navigateur.
void reloadPage() => impl.reloadPage();
