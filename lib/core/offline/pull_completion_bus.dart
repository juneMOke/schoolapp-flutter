import 'dart:async';

/// Bus de notification de **fin de pull** — pendant *lecture* de
/// `SyncEngine.addFlushCompleteListener` (qui, lui, signale la fin d'un flush
/// d'outbox).
///
/// Raison d'être : les écrans offline-first lisent le cache LOCAL, qui répond
/// en quelques millisecondes, alors que l'hydratation réseau déclenchée au
/// montage du `FeatureScope` met une à plusieurs secondes. Sans ce signal, un
/// cache froid s'affiche vide **et le reste** : la lecture est one-shot, rien
/// ne la rejoue quand les données arrivent enfin. L'utilisateur doit sortir de
/// la feature et y revenir — d'où l'impression tenace que « le pull ne marche
/// pas » alors qu'il a parfaitement fonctionné.
///
/// Les ressources diffusées sont les noms **logiques** des handlers
/// (`schedule_sessions`, `academics_cours`…), jamais les clés `sync_meta`
/// scopées par utilisateur (cf. `owner_scope.dart`) : un abonné raisonne sur
/// « la ressource X a changé », pas sur le compte qui l'a tirée.
///
/// Diffuse uniquement les ressources **effectivement mises à jour** : un cycle
/// `304`/`notModified` ne réveille personne (sinon chaque cycle de pull ferait
/// re-lire toute l'app pour rien).
class PullCompletionBus {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();

  /// Ressources mises à jour par un cycle de pull qui vient de se terminer.
  Stream<Set<String>> get stream => _controller.stream;

  /// Diffuse la fin d'un cycle. Sans effet si rien n'a bougé ou si le bus est
  /// fermé — **ne lève jamais** : un bus défaillant ne doit pas faire échouer
  /// le pull qui vient de réussir.
  void notifyUpdated(Set<String> resources) {
    if (resources.isEmpty || _controller.isClosed) return;
    _controller.add(Set.unmodifiable(resources));
  }

  /// Ferme le bus (app-lifetime en pratique : appelé par les tests).
  Future<void> dispose() => _controller.close();
}
