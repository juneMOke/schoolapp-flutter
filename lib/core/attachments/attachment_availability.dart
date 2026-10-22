import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/attachments/attachment_fetcher.dart';
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';

/// Ce qu'un écran sait de ses pièces : peut-il les ouvrir maintenant ?
///
/// Une pièce s'ouvre en ligne, ou hors ligne si elle est déjà dans le dossier
/// temporaire de la session. Ailleurs, son bouton est grisé.
class AttachmentAvailability extends Equatable {
  final bool online;

  /// Les empreintes déjà téléchargées pendant la session.
  final Set<String> cached;

  const AttachmentAvailability({this.online = true, this.cached = const {}});

  bool canOpen(AttachmentRef ref) => online || cached.contains(ref.sha256);

  AttachmentAvailability withOnline(bool online) =>
      AttachmentAvailability(online: online, cached: cached);

  AttachmentAvailability withCached(String sha256) =>
      AttachmentAvailability(online: online, cached: {...cached, sha256});

  @override
  List<Object?> get props => [online, cached];
}

/// Tient un [AttachmentAvailability] à jour pour un écran : la radio, et ce
/// que le dossier temporaire contient.
///
/// La radio n'est qu'une pré-garde (cf. [ConnectivityService]) : un bouton
/// actif peut encore échouer, et l'écran le dit alors.
class AttachmentAvailabilityTracker {
  final ConnectivityService _connectivity;
  final AttachmentFetcher _fetcher;

  const AttachmentAvailabilityTracker(this._connectivity, this._fetcher);

  /// L'état de [refs] maintenant.
  Future<AttachmentAvailability> snapshot(Iterable<AttachmentRef> refs) async {
    final cached = <String>{};
    for (final ref in refs) {
      if (await _fetcher.isCached(ref)) cached.add(ref.sha256);
    }
    bool online;
    try {
      online = await _connectivity.isOnline();
    } catch (_) {
      // Radio illisible (test, plateforme) : on laisse essayer.
      online = true;
    }
    return AttachmentAvailability(online: online, cached: cached);
  }

  /// Appelle [onChanged] à chaque transition de la radio ; rend la fonction
  /// qui désabonne.
  void Function() watch(void Function(bool online) onChanged) {
    final subscription = _connectivity.onStatusChange.listen(
      onChanged,
      onError: (_) {},
    );
    return () => unawaited(subscription.cancel());
  }
}
