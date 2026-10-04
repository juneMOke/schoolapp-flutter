import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

/// Pose ou retire `window.onbeforeunload`. Le navigateur affiche son propre
/// message — aucun texte personnalisé n'est plus honoré.
void setUnloadGuard(bool active) {
  _window['onbeforeunload'] = active
      ? ((JSObject event) {
          event.callMethod('preventDefault'.toJS);
          event['returnValue'] = ''.toJS;
        }).toJS
      : null;
}
