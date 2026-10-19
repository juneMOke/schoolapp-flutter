import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

/// Navigateur : des adresses sans `#` (`/home`, pas `/#/home`), qu'on peut
/// recopier, mettre en favori et rouvrir. Le serveur renvoie `index.html` pour
/// toute adresse inconnue (`deploy/web/nginx.conf`, `try_files`), sans quoi
/// un rafraîchissement rendrait une 404. Sans effet hors du web.
///
/// Une fiche poussée (`push`) écrit aussi son adresse : rechargée, elle se
/// rouvre au lieu de rendre la liste d'en dessous. Chacune sait se
/// reconstruire sans `extra` — identité relue en base (`StudentRecordRoutes`),
/// critères lus dans l'adresse (contrôle des frais, dossier d'inscription) ;
/// l'encaissement, lui, revient à sa fiche.
void useCleanWebUrls() {
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
}
