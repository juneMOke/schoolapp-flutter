import 'dart:async';
import 'dart:js_interop';

import 'package:school_app_flutter/core/web/tab_channel/tab_channel.dart';

@JS('BroadcastChannel')
extension type _BroadcastChannel._(JSObject _) implements JSObject {
  external _BroadcastChannel(String name);

  external void postMessage(JSAny? message);

  external set onmessage(JSFunction? handler);

  external void close();
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

TabChannel openTabChannel(String name) => _WebTabChannel(name);

class _WebTabChannel implements TabChannel {
  final _BroadcastChannel _channel;
  final _messages = StreamController<String>.broadcast();

  _WebTabChannel(String name) : _channel = _BroadcastChannel(name) {
    _channel.onmessage = ((_MessageEvent event) {
      final data = event.data;
      if (data != null && data.isA<JSString>()) {
        _messages.add((data as JSString).toDart);
      }
    }).toJS;
  }

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void post(String message) => _channel.postMessage(message.toJS);

  @override
  void close() {
    _channel
      ..onmessage = null
      ..close();
    unawaited(_messages.close());
  }
}
