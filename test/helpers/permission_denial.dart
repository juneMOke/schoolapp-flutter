import 'package:dio/dio.dart';

/// Le 403 que le serveur rend quand un DROIT manque (`@RequiresPermission` ou
/// contrôle de droit dans le code) : corps `ApiErrorResponse` au code
/// `FORBIDDEN`, sans `detailCode` — sauf [detailCode] pour les contrôles de
/// droit que le serveur nomme (`MONTH_CLOSURE_FORBIDDEN`…).
DioException permissionDenial403({
  Object? error,
  String path = '/',
  String? detailCode,
}) => DioException(
  requestOptions: RequestOptions(path: path),
  error: error,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: 403,
    data: <String, dynamic>{
      'code': 'FORBIDDEN',
      'message': 'Accès refusé.',
      'detailCode': ?detailCode,
    },
  ),
);
