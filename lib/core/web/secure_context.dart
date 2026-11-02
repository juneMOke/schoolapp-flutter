import 'package:school_app_flutter/core/web/secure_context_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/secure_context_web.dart'
    as impl;

/// La page est-elle servie dans un contexte sûr (https, ou localhost) ? Le
/// navigateur n'ouvre la caméra qu'à cette condition : en http, il ne
/// propose même pas la demande d'accès. Toujours vrai hors du web.
bool isSecureContext() => impl.isSecureContext();
