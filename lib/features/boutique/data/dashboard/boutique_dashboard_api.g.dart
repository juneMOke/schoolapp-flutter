// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boutique_dashboard_api.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _BoutiqueDashboardApi implements BoutiqueDashboardApi {
  _BoutiqueDashboardApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<BoutiqueStatsModel> getStats(
    Map<String, dynamic> extras,
    String from,
    String to,
    String academicYearId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'from': from,
      r'to': to,
      r'academicYearId': academicYearId,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<BoutiqueStatsModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/boutique/stats',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BoutiqueStatsModel _value;
    try {
      _value = BoutiqueStatsModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BoutiqueBeneficiariesPageModel> getBeneficiaries(
    Map<String, dynamic> extras,
    String from,
    String to,
    String academicYearId,
    String? articleId,
    String? classId,
    String? search,
    int page,
    int size,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'from': from,
      r'to': to,
      r'academicYearId': academicYearId,
      r'articleId': articleId,
      r'classId': classId,
      r'q': search,
      r'page': page,
      r'size': size,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<BoutiqueBeneficiariesPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/boutique/beneficiaries',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BoutiqueBeneficiariesPageModel _value;
    try {
      _value = BoutiqueBeneficiariesPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
