import 'package:flutter_web_plugins/url_strategy.dart';

/// Navigateur : des adresses sans `#` (`/home`, pas `/#/home`), qu'on peut
/// recopier, mettre en favori et rouvrir. Le serveur renvoie `index.html` pour
/// toute adresse inconnue (`deploy/web/nginx.conf`, `try_files`), sans quoi
/// un rafraîchissement rendrait une 404. Sans effet hors du web.
///
/// Les pages poussées (`push`) n'écrivent PAS leur adresse
/// (`GoRouter.optionURLReflectsImperativeAPIs` reste à `false`) : chaque
/// `push` deviendrait une entrée d'historique, et Précédent rouvrirait un
/// encaissement déjà écrit sur ses soldes d'avant. Une fiche ouverte par son
/// adresse (lien collé, favori) se reconstruit seule (`StudentRecordRoutes`).
void useCleanWebUrls() => usePathUrlStrategy();
