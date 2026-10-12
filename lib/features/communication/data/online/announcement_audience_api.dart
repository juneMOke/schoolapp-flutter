import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/communication/data/wire/audience_wire.dart';
import 'package:school_app_flutter/features/communication/data/wire/reach_wire.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

/// La portée et la recherche d'élèves, sur Dio.
class AnnouncementAudienceApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const AnnouncementAudienceApi(this._dio, this._extras);

  Future<AnnouncementReach> reach(AnnouncementAudience audience) async {
    final response = await _dio.post<Object?>(
      AppConstants.announcementReachEndpoint,
      data: {'audience': AudienceWire.toJson(audience)},
      options: Options(extra: _extras),
    );
    return ReachWire.fromJson(response.data) ??
        (throw const FormatException('Portée illisible'));
  }

  Future<List<AudienceStudent>> searchStudents(String query) async {
    final response = await _dio.get<Object?>(
      AppConstants.announcementAudienceStudentsEndpoint,
      queryParameters: {'q': query.trim()},
      options: Options(extra: _extras),
    );
    final body = response.data;
    return [
      if (body is List)
        for (final item in body) ?AudienceWire.studentOf(item),
    ];
  }
}
