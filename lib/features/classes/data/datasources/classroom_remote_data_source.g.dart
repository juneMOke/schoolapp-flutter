// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'classroom_remote_data_source.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main

class _ClassroomRemoteDataSource implements ClassroomRemoteDataSource {
  _ClassroomRemoteDataSource(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<List<ClassroomModel>> listClassroomsByLevelAndAcademicYear(
    Map<String, dynamic> extras,
    String schoolLevelGroupId,
    String schoolLevelId,
    String academicYearId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'schoolLevelGroupId': schoolLevelGroupId,
      r'schoolLevelId': schoolLevelId,
      r'academicYearId': academicYearId,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<List<ClassroomModel>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classrooms',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<List<dynamic>>(_options);
    late List<ClassroomModel> _value;
    try {
      _value = _result.data!
          .map(
            (dynamic i) => ClassroomModel.fromJson(i as Map<String, dynamic>),
          )
          .toList();
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<List<ClassroomMemberModel>> listClassroomMembers(
    Map<String, dynamic> extras,
    String classroomId,
    String academicYearId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'academicYearId': academicYearId,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<List<ClassroomMemberModel>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classrooms/${classroomId}/members',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<List<dynamic>>(_options);
    late List<ClassroomMemberModel> _value;
    try {
      _value = _result.data!
          .map(
            (dynamic i) =>
                ClassroomMemberModel.fromJson(i as Map<String, dynamic>),
          )
          .toList();
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<LevelDistributionOverviewModel> getLevelDistributionOverview(
    Map<String, dynamic> extras,
    String academicYearId,
    String schoolLevelId,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{
      r'academicYearId': academicYearId,
      r'schoolLevelId': schoolLevelId,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<LevelDistributionOverviewModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classrooms/distribution-overview',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late LevelDistributionOverviewModel _value;
    try {
      _value = LevelDistributionOverviewModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<ClassroomStatsResponseModel> getClassroomStats(
    Map<String, dynamic> extras,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<ClassroomStatsResponseModel>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classroom-stats',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late ClassroomStatsResponseModel _value;
    try {
      _value = ClassroomStatsResponseModel.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<void> distributeStudentsToClassrooms(
    Map<String, dynamic> extras,
    DistributionRequestModel request,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<void>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classrooms/distribute',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
  }

  @override
  Future<void> reassignClassroomMember(
    Map<String, dynamic> extras,
    String targetClassroomId,
    String classroomMemberId,
    ReassignClassroomMemberRequestModel request,
  ) async {
    final _extra = <String, dynamic>{};
    _extra.addAll(extras);
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<void>(
      Options(method: 'PUT', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/api/v1/classrooms/${targetClassroomId}/members/${classroomMemberId}',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
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
