{{flutter_js}}
{{flutter_build_config}}

// Démarrage SANS service worker. Le chargeur par défaut attendait jusqu'à 4 s
// l'enregistrement d'un service worker — que Flutter désinscrit aussitôt —
// AVANT de télécharger l'application, à chaque visite. Le cache est celui de
// nginx (`no-cache` + ETag : un fichier inchangé répond 304).
//
// Un échec de chargement (réseau coupé, fichier absent) le dit sur le
// pré-splash au lieu d'y laisser tourner l'arc indéfiniment.
var loading = _flutter.loader.load();
if (loading && typeof loading.catch === 'function') {
  loading.catch(function (error) {
    if (window.showSplashFailure) window.showSplashFailure();
    throw error;
  });
}
