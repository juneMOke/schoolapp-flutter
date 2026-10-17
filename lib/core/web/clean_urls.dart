import 'package:flutter_web_plugins/url_strategy.dart';

/// Navigateur : des adresses sans `#` (`/home`, pas `/#/home`), qu'on peut
/// recopier, mettre en favori et rouvrir. Le serveur renvoie `index.html` pour
/// toute adresse inconnue (`deploy/web/nginx.conf`, `try_files`), sans quoi
/// un rafraîchissement rendrait une 404. Sans effet hors du web.
void useCleanWebUrls() => usePathUrlStrategy();
