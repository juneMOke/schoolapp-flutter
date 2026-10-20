import 'package:school_app_flutter/core/web/tab_channel/tab_channel_stub.dart'
    if (dart.library.js_interop) 'package:school_app_flutter/core/web/tab_channel/tab_channel_web.dart'
    as impl;

/// Un canal entre les onglets de l'application ouverts dans le même
/// navigateur (`BroadcastChannel`). Un message posté n'est reçu que par les
/// AUTRES onglets. Muet hors du web : une application installée n'a qu'une
/// fenêtre.
abstract interface class TabChannel {
  /// Les messages des autres onglets.
  Stream<String> get messages;

  void post(String message);

  void close();

  /// Le canal [name] de cette plateforme.
  factory TabChannel(String name) => impl.openTabChannel(name);
}
