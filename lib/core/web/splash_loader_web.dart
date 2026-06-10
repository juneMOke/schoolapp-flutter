import 'dart:js_interop';

/// Référence la fonction globale `window.removeSplashLoader` (définie dans
/// `web/index.html`). `null` si absente (build sans le loader).
@JS('removeSplashLoader')
external JSFunction? get _removeSplashLoader;

/// Déclenche la disparition du pré-splash HTML. Sûr si la fonction n'existe pas.
void removeWebSplashLoader() {
  _removeSplashLoader?.callAsFunction();
}
