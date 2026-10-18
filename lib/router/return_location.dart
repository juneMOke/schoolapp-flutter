/// L'adresse demandée, portée à travers le splash et la connexion.
///
/// Sur le web, un F5, un favori ou un lien collé démarrent l'application sur
/// une adresse précise. Or la session n'est pas encore restaurée : le routeur
/// déroute vers `/splash`, puis — une fois la session prête — vers `/home`.
/// Sans mémoire, l'adresse demandée était perdue et l'on retombait toujours
/// sur l'Accueil.
///
/// Elle voyage donc dans la requête (`/splash?from=/finances/…`), et non dans
/// un état en mémoire : c'est l'URL qui survit à un rechargement, rien d'autre.
library;

/// Paramètre de requête qui porte l'adresse à rendre.
const String kReturnToParam = 'from';

/// Premiers segments qui ne sont jamais une destination : y revenir bouclerait
/// sur le parcours d'entrée lui-même.
const Set<String> _entrySegments = {'splash', 'login', 'forgot-password'};

/// [location] si c'est une destination légitime à rendre plus tard, sinon
/// `null`.
///
/// Refuse tout ce qui n'est pas un chemin interne (schéma, hôte, `//…` : la
/// valeur vient d'une URL qu'un tiers peut forger), le parcours d'entrée, et
/// `/home` — qui est déjà la destination par défaut.
String? sanitizeReturnLocation(String? location) {
  if (location == null || location.isEmpty) return null;
  if (!location.startsWith('/') || location.startsWith('//')) return null;
  final uri = Uri.tryParse(location);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  if (_entrySegments.contains(segments.first)) return null;
  if (segments.length == 1 && segments.first == 'home' && !uri.hasQuery) {
    return null;
  }
  return uri.toString();
}

/// L'adresse en attente portée par [location] (`?from=`), validée.
String? pendingReturnLocation(Uri location) =>
    sanitizeReturnLocation(location.queryParameters[kReturnToParam]);

/// [path] augmenté de l'adresse à rendre, s'il y en a une.
String withReturnLocation(String path, String? returnTo) {
  if (returnTo == null) return path;
  return Uri(
    path: path,
    queryParameters: {kReturnToParam: returnTo},
  ).toString();
}
