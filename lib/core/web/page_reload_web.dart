import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window.location')
external JSObject get _location;

void reloadPage() => _location.callMethod('reload'.toJS);
