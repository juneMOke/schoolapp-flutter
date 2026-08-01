import 'package:dio/dio.dart';

/// Journal réseau verbeux qui ne déverse jamais un corps **binaire**.
///
/// Le `LogInterceptor` de Dio imprime `response.data` via `toString()`. Sur du
/// JSON c'est lisible ; sur les octets d'un PDF d'éditique,
/// `Uint8List.toString()` produit `[37, 80, 68, 70, …]` — des dizaines de
/// milliers d'entiers sur une seule ligne, qui noient le journal et peuvent
/// faire tomber la sortie de `flutter run`. Le corps binaire est donc résumé
/// (taille + type MIME) au lieu d'être imprimé.
///
/// Ré-implémenté plutôt que dérivé de [LogInterceptor] : celui-ci imprime *puis*
/// propage dans la même méthode, donc le rendre muet ponctuellement supposerait
/// soit de muter la réponse en vol, soit de lui passer un faux handler. Les deux
/// dépendent de détails internes de Dio ; ces ~70 lignes n'en dépendent pas.
///
/// N'est monté que lorsque `EnvConfig.enableVerboseNetworkLogging` est vrai.
class BinarySafeLogInterceptor extends Interceptor {
  final bool logRequestBody;
  final bool logResponseBody;
  final void Function(Object object) logPrint;

  BinarySafeLogInterceptor({
    this.logRequestBody = true,
    this.logResponseBody = true,
    this.logPrint = print,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logPrint('*** Request ***');
    logPrint('uri: ${options.uri}');
    logPrint('method: ${options.method}');
    logPrint('responseType: ${options.responseType}');
    logPrint('headers:');
    options.headers.forEach((key, value) => logPrint(' $key: $value'));
    if (logRequestBody && options.data != null) {
      logPrint('data:');
      logPrint(_describe(options.data, options.contentType));
    }
    logPrint('');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _printResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logPrint('*** DioException ***:');
    logPrint('uri: ${err.requestOptions.uri}');
    logPrint('$err');
    final response = err.response;
    if (response != null) {
      _printResponse(response);
    }
    logPrint('');
    handler.next(err);
  }

  void _printResponse(Response<dynamic> response) {
    logPrint('*** Response ***');
    logPrint('uri: ${response.realUri}');
    logPrint('statusCode: ${response.statusCode}');
    logPrint('headers:');
    response.headers.forEach(
      (key, values) => logPrint(' $key: ${values.join('\r\n\t')}'),
    );
    if (logResponseBody) {
      logPrint('Response Text:');
      logPrint(
        _describe(
          response.data,
          response.headers.value(Headers.contentTypeHeader),
        ),
      );
    }
    logPrint('');
  }

  /// Rend [data] imprimable : résumé pour un corps binaire, `toString()` sinon.
  static String _describe(Object? data, String? contentType) {
    if (data is List<int>) {
      return '<corps binaire non journalisé — ${data.length} octets, '
          '${contentType ?? 'type inconnu'}>';
    }
    return data.toString();
  }
}
