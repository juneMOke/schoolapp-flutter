import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const bool canDownloadTextFiles = true;

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('document')
external JSObject get _document;

/// Un lien `download` cliqué puis retiré : le geste qu'un navigateur
/// reconnaît pour enregistrer un fichier.
void downloadTextFile({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  final options = JSObject()..['type'] = mimeType.toJS;
  final blob = _Blob(<JSAny>[content.toJS].toJS, options);
  final url = _createObjectUrl(blob);
  final anchor = _document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS)
    ..['href'] = url.toJS
    ..['download'] = fileName.toJS;
  final body = _document['body'] as JSObject;
  body.callMethod('appendChild'.toJS, anchor);
  anchor.callMethod('click'.toJS);
  body.callMethod('removeChild'.toJS, anchor);
  _revokeObjectUrl(url);
}
