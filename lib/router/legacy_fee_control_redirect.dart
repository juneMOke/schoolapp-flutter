import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Les clés de l'ancienne adresse du contrôle des frais (avant la v2) et leur
/// nom d'aujourd'hui. `level` et `cycle` n'ont plus d'équivalent : la v2 lit
/// une classe ou la rubrique « Non affectés », jamais un niveau entier.
const _legacyKeys = {'fee': 'frais', 'classroom': 'classe'};
const _droppedKeys = {'level', 'cycle'};

/// L'ancienne adresse `/recouvrement/recouvrement-controle?…` renvoie au
/// sous-menu de la coquille (spec v2, R15), question comprise : `fee` devient
/// `frais`, `classroom` devient `classe`, `level` et `cycle` tombent. Une clé
/// déjà dans le vocabulaire v2 passe telle quelle et prime sur l'ancienne.
String legacyFeeControlRedirect(Map<String, String> queryParameters) {
  final params = <String, String>{};
  for (final entry in queryParameters.entries) {
    if (_droppedKeys.contains(entry.key)) continue;
    final key = _legacyKeys[entry.key];
    if (key != null) {
      params.putIfAbsent(key, () => entry.value);
    } else {
      params[entry.key] = entry.value;
    }
  }
  return Uri(
    path: AppRoutesNames.homeSubMenuPath(MenuConstants.recouvrementControlId),
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}
