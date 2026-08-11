import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/router/app_router.dart';

/// Invariant de la garde de route (ADR-014 §2.9) : **toute route déclarée est
/// gardée, ou ouverte par décision inscrite ici**.
///
/// Ce test existe parce que le précédent ne suffisait pas. Un trou avait été
/// trouvé — `/enrollments/detail/:id`, dont le second segment est le mot
/// `detail` et non un identifiant de sous-menu — et le test écrit alors figeait
/// la *correction* : il vérifiait que la clé `enrollments` était bien déclarée.
/// Il serait resté vert pour toujours, y compris devant une route neuve tombant
/// dans exactement le même piège.
///
/// Celui-ci fige la *propriété*. Il parcourt l'arbre réellement déclaré par
/// `AppRouter.buildRoutes()` et exige de chaque chemin qu'il refuse un porteur
/// sans aucun droit. La liste blanche ci-dessous est le seul endroit où une
/// exception s'écrit — et l'y ajouter est un geste visible en revue.
void main() {
  /// Chemins délibérément ouverts, avec la raison de chacun. Un ajout ici doit
  /// se justifier : ce sont les seules portes que le fail-closed ne ferme pas.
  const ouvertesParDecision = <String, String>{
    '/splash': 'amorçage — précède la résolution des droits',
    '/login':
        'authentification — exiger un droit pour se connecter serait circulaire',
    '/forgot-password/email': 'flux de réinitialisation, hors session',
    '/forgot-password/otp': 'flux de réinitialisation, hors session',
    '/forgot-password/reset': 'flux de réinitialisation, hors session',
    '/home':
        'coquille et grille d\'accueil — elles se filtrent elles-mêmes, et '
        'c\'est la seule porte qui reste quand tout le reste est masqué',
    '/dev/components': 'galerie de composants, kDebugMode uniquement',
    '/dev/ticket-print': 'banc de calage thermique, kDebugMode uniquement',
  };

  /// Aplatit l'arbre en chemins absolus. Les enfants portent tantôt un chemin
  /// absolu (les constantes de `AppRoutesNames`), tantôt un suffixe relatif
  /// (`detail/:studentId/...`) — les deux coexistent dans le routeur.
  List<String> aplatir(List<RouteBase> routes, [String parent = '']) {
    final chemins = <String>[];
    for (final route in routes) {
      if (route is GoRoute) {
        final chemin = route.path.startsWith('/')
            ? route.path
            : '$parent/${route.path}';
        chemins.add(chemin);
        chemins.addAll(aplatir(route.routes, chemin));
      } else if (route is ShellRoute) {
        chemins.addAll(aplatir(route.routes, parent));
      }
    }
    return chemins;
  }

  /// Un chemin déclaré porte des paramètres (`:studentId`) : on les substitue,
  /// la garde ne lit que les segments littéraux de tête.
  Uri concret(String chemin) => Uri.parse(
    chemin.split('/').map((s) => s.startsWith(':') ? 'x' : s).join('/'),
  );

  test('toute route déclarée refuse un porteur sans aucun droit', () {
    final manquantes = <String>[];

    for (final chemin in aplatir(AppRouter.buildRoutes())) {
      if (ouvertesParDecision.containsKey(chemin)) continue;
      if (!canAccessLocation(concret(chemin), const <String>[])) continue;
      manquantes.add(chemin);
    }

    expect(
      manquantes,
      isEmpty,
      reason:
          'Ces routes sont atteignables sans aucun droit. Soit leur segment de '
          'tête doit être déclaré (kModuleAccessRegistry pour une route de '
          'coquille, kStandaloneRouteAccess pour une route de premier niveau), '
          'soit leur ouverture doit être inscrite — et justifiée — dans '
          '`ouvertesParDecision` de ce test.',
    );
  });

  // Le pendant : sans cette vérification, on fermerait la liste blanche en la
  // vidant, et le test ci-dessus resterait vert sur une application inutilisable.
  test('les routes ouvertes par décision le sont réellement', () {
    final declarees = aplatir(AppRouter.buildRoutes()).toSet();

    for (final chemin in ouvertesParDecision.keys) {
      expect(
        declarees,
        contains(chemin),
        reason:
            '$chemin est excusé par ce test mais n\'existe plus dans le '
            'routeur : l\'exception survit à la route qu\'elle couvrait.',
      );
      expect(
        canAccessLocation(concret(chemin), const <String>[]),
        isTrue,
        reason:
            '$chemin est censé rester ouvert : ${ouvertesParDecision[chemin]}',
      );
    }
  });

  // La route qui a produit le trou d'origine, gardée nommément : elle est de
  // premier niveau, donc elle ne peut pas passer par le registre des sous-menus.
  test('le détail d\'inscription reste couvert', () {
    expect(
      canAccessLocation(Uri.parse('/enrollments/detail/e-1'), const <String>[]),
      isFalse,
    );
    expect(
      canAccessLocation(Uri.parse('/enrollments/detail/e-1'), const [
        'enrollment.read',
      ]),
      isTrue,
    );
  });
}
