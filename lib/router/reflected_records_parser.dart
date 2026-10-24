import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les fiches **en lecture** ouvertes par `push` prennent leur adresse dans la
/// barre du navigateur : F5, un favori, « copier l'adresse » y ramènent, et
/// Précédent revient à la liste qui les a ouvertes, restée en dessous.
///
/// Sélectif, à la différence de `GoRouter.optionURLReflectsImperativeAPIs`
/// (essayé puis écarté) : un ENCAISSEMENT ne reçoit jamais d'adresse propre —
/// chaque `push` deviendrait une entrée d'historique, et Suivant rouvrirait un
/// encaissement déjà écrit sur ses anciens soldes. Poussé sur une fiche, il
/// garde l'adresse de la fiche. (L'historique du navigateur garde quand même
/// sa trace — go_router enregistre la pile — d'où l'encaissement « consommé »
/// qui ne se rouvre plus, cf. `FacturationCreatePaymentIntent.isSpent`.)
///
/// Ces fiches se reconstruisent depuis leurs identifiants quand l'`extra` de la
/// navigation manque (`StudentRecordRoutes`, catalogue des documents).
class ReflectedRecordsParser extends RouteInformationParser<RouteMatchList> {
  /// Les fiches qui ont une adresse, par motif de route.
  static const Set<String> reflectedPaths = {
    AppRoutesNames.facturationDetail,
    AppRoutesNames.documentsCatalog,
    AppRoutesNames.disciplinaryStudentDetail,
    AppRoutesNames.hrPersonnelAgent,
  };

  final GoRouteInformationParser _inner;

  ReflectedRecordsParser(this._inner);

  /// La configuration du [router], dont seul l'analyseur change.
  static RouterConfig<RouteMatchList> configOf(GoRouter router) =>
      RouterConfig<RouteMatchList>(
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: ReflectedRecordsParser(
          router.routeInformationParser,
        ),
        routerDelegate: router.routerDelegate,
        backButtonDispatcher: router.backButtonDispatcher,
      );

  @override
  Future<RouteMatchList> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) => _inner.parseRouteInformationWithDependencies(routeInformation, context);

  @override
  RouteInformation? restoreRouteInformation(RouteMatchList configuration) {
    final restored = _inner.restoreRouteInformation(configuration);
    if (restored == null) return null;
    final reflected = reflectedUri(configuration);
    if (reflected == null) return restored;
    return RouteInformation(uri: reflected, state: restored.state);
  }

  /// L'adresse de la fiche en lecture la plus haute de la pile ; `null` s'il
  /// n'y en a pas (l'adresse reste celle de la page de base).
  ///
  /// Un écran poussé PAR-DESSUS une fiche (encaissement) ne la masque pas : il
  /// n'a pas d'adresse, la barre garde celle de la fiche.
  ///
  /// Une fiche poussée sous une `ShellRoute` (le scope d'une fonctionnalité)
  /// est rangée DANS la correspondance de la coquille : on y descend.
  @visibleForTesting
  static Uri? reflectedUri(RouteMatchList configuration) =>
      _reflectedIn(configuration.matches);

  static Uri? _reflectedIn(List<RouteMatchBase> matches) {
    for (final match in matches.reversed) {
      if (match is ImperativeRouteMatch &&
          reflectedPaths.contains(match.matches.fullPath)) {
        return match.matches.uri;
      }
      if (match is ShellRouteMatch) {
        final nested = _reflectedIn(match.matches);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}
