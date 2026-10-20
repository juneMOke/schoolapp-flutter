import 'package:school_app_flutter/core/web/tab_channel/tab_channel.dart';

/// Implémentation non-web : aucun autre onglet.
TabChannel openTabChannel(String name) => const _SilentTabChannel();

class _SilentTabChannel implements TabChannel {
  const _SilentTabChannel();

  @override
  Stream<String> get messages => const Stream.empty();

  @override
  void post(String message) {}

  @override
  void close() {}
}
