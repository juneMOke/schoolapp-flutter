/// Aucune école n'est attachée : aucune session n'est ouverte, ou elle vient de
/// se fermer.
///
/// Un échec TYPÉ plutôt qu'un vide (MULTI_ECOLE_PLAN.md, lot 3) : une lecture
/// qui rendrait « aucune ligne » avant l'authentification serait indiscernable
/// d'une école réellement vide, et un écran l'afficherait comme telle.
class NoTenantAttachedException implements Exception {
  const NoTenantAttachedException();

  @override
  String toString() => 'NoTenantAttachedException: aucune école attachée';
}

/// Un travail lié à une école a tenté d'accéder à la base après que l'école a
/// changé.
///
/// Le cas qu'elle existe à fermer : un pull parti pour l'école A attend sa
/// réponse réseau ; A se déconnecte, B se connecte ; la réponse arrive. Sans
/// cette levée, la page de A et son curseur s'écriraient dans la base de B —
/// les élèves de A listés chez B, et le curseur de B avancé jusqu'au point où
/// A en était, ce qui priverait B de tout ce qui précède.
class StaleTenantException implements Exception {
  const StaleTenantException();

  @override
  String toString() =>
      'StaleTenantException: l\'école a changé pendant le travail';
}

/// Portée d'école d'un travail asynchrone — un flush, un cycle de pull.
///
/// Se lie à l'école attachée **au départ** du travail, pas à celle qui le sera
/// quand il écrira : c'est entre les deux qu'une attente réseau laisse le temps
/// à une bascule de session.
abstract interface class TenantScope {
  /// Exécute [body] lié à l'école attachée à cet instant.
  ///
  /// Toute opération de base que [body] fera ensuite, y compris après une
  /// attente réseau, lèvera [StaleTenantException] si l'école a changé
  /// entre-temps.
  Future<T> run<T>(Future<T> Function() body);

  /// Vrai si le travail en cours a été lié à une école qui n'est plus
  /// attachée. Faux hors de toute portée.
  bool get isStale;
}

/// Portée qui ne lie rien : moteurs construits sans base par école (tests).
class UnboundTenantScope implements TenantScope {
  const UnboundTenantScope();

  @override
  Future<T> run<T>(Future<T> Function() body) => body();

  @override
  bool get isStale => false;
}
