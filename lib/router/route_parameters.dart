import 'package:go_router/go_router.dart';

/// Vrai quand chacun des paramètres de chemin [keys] est renseigné : une
/// route qui en manque redirige plutôt que d'ouvrir une fiche vide.
bool hasRequiredPathParameters(GoRouterState state, List<String> keys) {
  for (final key in keys) {
    final value = state.pathParameters[key] ?? '';
    if (value.trim().isEmpty) return false;
  }
  return true;
}
