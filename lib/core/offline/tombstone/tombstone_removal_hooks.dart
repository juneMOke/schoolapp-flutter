/// Ce qu'un module fait **hors de la base** quand le serveur retire une ligne
/// qu'il possède : des octets scellés sur disque, qu'aucune table fille ne
/// désigne plus une fois la ligne partie.
///
/// Appelés APRÈS l'effacement, avec l'identifiant de la ligne retirée. Un
/// crochet qui échoue n'arrête pas le retrait : c'est de l'hygiène de disque.
class TombstoneRemovalHooks {
  final Map<String, List<Future<void> Function(String entityId)>> _hooks = {};

  /// [resource] : la clé serveur de [kTombstoneTargets] (`students`…).
  void add(String resource, Future<void> Function(String entityId) hook) =>
      (_hooks[resource] ??= []).add(hook);

  Future<void> run(String resource, String entityId) async {
    for (final hook in _hooks[resource] ?? const []) {
      try {
        await hook(entityId);
      } catch (_) {
        // Fichier verrouillé, magasin indisponible : le retrait reste acquis.
      }
    }
  }
}
