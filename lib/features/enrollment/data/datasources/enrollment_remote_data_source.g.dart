// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment_remote_data_source.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _EnrollmentRemoteDataSource implements EnrollmentRemoteDataSource {
  _EnrollmentRemoteDataSource(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<EnrollmentSummaryPageModel>
  getEnrollmentSummaryByStatusAndAcademicYear(
    Map<String, dynamic> extras,
    String status,
    String academicYearId,
    int page,
    int size,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'status': status,
      r'academicYearId': academicYearId,
      r'page': page,
      r'size': size,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentSummaryPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentSummaryPageModel _value;
    try {
      _value = EnrollmentSummaryPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentName(
    Map<String, dynamic> extras,
    String status,
    String academicYearId,
    String firstName,
    String lastName,
    String surname,
    int page,
    int size,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'status': status,
      r'academicYearId': academicYearId,
      r'firstName': firstName,
      r'lastName': lastName,
      r'surname': surname,
      r'page': page,
      r'size': size,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentSummaryPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments/search/by-names',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentSummaryPageModel _value;
    try {
      _value = EnrollmentSummaryPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirth(
    Map<String, dynamic> extras,
    String status,
    String academicYearId,
    String firstName,
    String lastName,
    String surname,
    String dateOfBirth,
    int page,
    int size,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'status': status,
      r'academicYearId': academicYearId,
      r'firstName': firstName,
      r'lastName': lastName,
      r'surname': surname,
      r'dateOfBirth': dateOfBirth,
      r'page': page,
      r'size': size,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentSummaryPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments/search/by-names-and-dob',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentSummaryPageModel _value;
    try {
      _value = EnrollmentSummaryPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentSummaryPageModel>
  searchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirth(
    Map<String, dynamic> extras,
    String status,
    String academicYearId,
    String dateOfBirth,
    int page,
    int size,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'status': status,
      r'academicYearId': academicYearId,
      r'dateOfBirth': dateOfBirth,
      r'page': page,
      r'size': size,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentSummaryPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments/search/by-date-of-birth',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentSummaryPageModel _value;
    try {
      _value = EnrollmentSummaryPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentDetailModel> getEnrollmentPreviewByStudentId(
    Map<String, dynamic> extras,
    String studentId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentDetailModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments/students/${studentId}/preview',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentDetailModel _value;
    try {
      _value = EnrollmentDetailModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentDetailModel> getEnrollmentDetail(
    Map<String, dynamic> extras,
    String enrollmentId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentDetailModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollments/${enrollmentId}/detail',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentDetailModel _value;
    try {
      _value = EnrollmentDetailModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentStatsResponseModel> getEnrollmentStats(
    Map<String, dynamic> extras,
    String period,
    String? date,
    String? from,
    String? to,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'period': period,
      r'date': date,
      r'from': from,
      r'to': to,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentStatsResponseModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollment-stats',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentStatsResponseModel _value;
    try {
      _value = EnrollmentStatsResponseModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<EnrollmentEntriesPageModel> getEntries(
    Map<String, dynamic> extras,
    String period,
    String? date,
    String? from,
    String? to,
    int page,
    int size,
    String sort,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'period': period,
      r'date': date,
      r'from': from,
      r'to': to,
      r'page': page,
      r'size': size,
      r'sort': sort,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<EnrollmentEntriesPageModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/enrollment-stats/entries',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late EnrollmentEntriesPageModel _value;
    try {
      _value = EnrollmentEntriesPageModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<Uint8List>> getEntriesReport(
    Map<String, dynamic> extras,
    String period,
    String? date,
    String? from,
    String? to,
    String sort,
    Options options,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'period': period,
      r'date': date,
      r'from': from,
      r'to': to,
      r'sort': sort,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{
      r'Accept': 'application/pdf, application/json',
    };
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final newOptions = newRequestOptions(options);
    newOptions.extra.addAll(_extra);
    newOptions.headers.addAll(_dio.options.headers);
    newOptions.headers.addAll(_headers);
    final _options = newOptions.copyWith(
      method: 'GET',
      baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
      responseType: ResponseType.bytes,
      queryParameters: queryParameters,
      path: '/api/v1/enrollment-stats/entries.pdf',
    )..data = _data;
    final _result = await _dio.fetch<Uint8List>(_options);
    late Uint8List _value;
    try {
      _value = _result.data!;
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  RequestOptions newRequestOptions(Object? options) {
    if (options is RequestOptions) {
      return options;
    }
    if (options is Options) {
      return RequestOptions(
        method: options.method,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        extra: options.extra,
        headers: options.headers,
        responseType: options.responseType,
        contentType: options.contentType.toString(),
        validateStatus: options.validateStatus,
        receiveDataWhenStatusError: options.receiveDataWhenStatusError,
        followRedirects: options.followRedirects,
        maxRedirects: options.maxRedirects,
        requestEncoder: options.requestEncoder,
        responseDecoder: options.responseDecoder,
        path: '',
      );
    }
    return RequestOptions(path: '');
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
