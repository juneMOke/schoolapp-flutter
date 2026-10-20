import 'package:go_router/go_router.dart';

/// L'état d'un écran tenu dans la requête de son adresse (`?onglet=…`,
/// `?eleve=…`) : F5 le retrouve, Précédent y revient, l'adresse se partage.
abstract final class LocationQuery {
  /// La valeur de [key] dans l'adresse courante de [router].
  static String? read(GoRouter router, String key) =>
      router.routerDelegate.currentConfiguration.uri.queryParameters[key];

  /// Change [values] dans l'adresse courante (`null` retire la clé), sans
  /// toucher au reste ; rien quand l'adresse ne change pas.
  static void write(GoRouter router, Map<String, String?> values) {
    final uri = router.routerDelegate.currentConfiguration.uri;
    final next = withValues(uri, values);
    if (next != uri) router.go(next.toString());
  }

  static Uri withValues(Uri uri, Map<String, String?> values) {
    final query = {...uri.queryParameters};
    values.forEach((key, value) {
      if (value == null || value.isEmpty) {
        query.remove(key);
      } else {
        query[key] = value;
      }
    });
    // `replace(queryParameters: null)` garderait l'ancienne requête.
    return query.isEmpty
        ? Uri(path: uri.path)
        : uri.replace(queryParameters: query);
  }
}
