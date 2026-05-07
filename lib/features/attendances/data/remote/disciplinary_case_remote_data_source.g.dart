// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disciplinary_case_remote_data_source.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _DisciplinaryCaseRemoteDataSource
    implements DisciplinaryCaseRemoteDataSource {
  _DisciplinaryCaseRemoteDataSource(
    this._dio, {
    this.baseUrl,
    this.errorLogger,
  });

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<List<DisciplinaryCaseSummaryModel>>
  fetchDisciplinaryCasesByStudentAndYear(
    Map<String, dynamic> extras,
    String studentId,
    String academicYearId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'studentId': studentId,
      r'academicYearId': academicYearId,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<List<DisciplinaryCaseSummaryModel>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/disciplinary-cases',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<List<dynamic>>(_options);
    late List<DisciplinaryCaseSummaryModel> _value;
    try {
      _value = _result.data!
          .map(
            (dynamic i) => DisciplinaryCaseSummaryModel.fromJson(
              i as Map<String, dynamic>,
            ),
          )
          .toList();
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<DisciplinaryCaseDetailModel> getCaseById(
    Map<String, dynamic> extras,
    String caseId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<DisciplinaryCaseDetailModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/disciplinary-cases/${caseId}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late DisciplinaryCaseDetailModel _value;
    try {
      _value = DisciplinaryCaseDetailModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<DisciplinaryCaseSummaryModel> createCase(
    Map<String, dynamic> extras,
    CreateDisciplinaryCaseRequestModel request,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<DisciplinaryCaseSummaryModel>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/disciplinary-cases',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late DisciplinaryCaseSummaryModel _value;
    try {
      _value = DisciplinaryCaseSummaryModel.fromJson(_result.data!);
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
