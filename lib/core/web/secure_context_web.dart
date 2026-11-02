import 'dart:js_interop';

@JS('window.isSecureContext')
external bool get _isSecureContext;

bool isSecureContext() => _isSecureContext;
