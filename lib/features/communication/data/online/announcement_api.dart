import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/communication/data/wire/announcement_wire.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';

/// Les gestes qui font bouger le statut d'un communiqué.
enum AnnouncementGesture { schedule, unschedule, send, cancel }

/// Les communiqués sur Dio, lus à la main : une ligne illisible est écartée.
class AnnouncementApi {
  final Dio _dio;
  final Map<String, dynamic> _extras;

  const AnnouncementApi(this._dio, this._extras);

  Options get _options => Options(extra: _extras);

  Future<List<Announcement>> list({String? academicYearId}) async {
    final response = await _dio.get<Object?>(
      AppConstants.announcementsEndpoint,
      queryParameters: {'academicYearId': ?academicYearId},
      options: _options,
    );
    return AnnouncementWire.listFromJson(response.data);
  }

  Future<Announcement> get(String id) async {
    final response = await _dio.get<Object?>(_one(id), options: _options);
    return _read(response.data);
  }

  Future<Announcement> create({
    required String id,
    required AnnouncementContent content,
    String? academicYearId,
  }) async {
    final response = await _dio.post<Object?>(
      AppConstants.announcementsEndpoint,
      data: {
        'id': id,
        'academicYearId': ?academicYearId,
        ...AnnouncementWire.contentToJson(content),
      },
      options: _options,
    );
    return _read(response.data);
  }

  Future<Announcement> update(
    String id,
    AnnouncementContent content, {
    required int version,
  }) async {
    final response = await _dio.put<Object?>(
      _one(id),
      data: {...AnnouncementWire.contentToJson(content), 'version': version},
      options: _options,
    );
    return _read(response.data);
  }

  /// Un geste : la `version` vue, et le moment pour une programmation.
  Future<Announcement> gesture(
    String id,
    AnnouncementGesture gesture, {
    required int version,
    DateTime? scheduledAt,
  }) async {
    final response = await _dio.post<Object?>(
      AppConstants.announcementGestureEndpoint
          .replaceFirst('{id}', Uri.encodeComponent(id))
          .replaceFirst('{gesture}', gesture.name),
      data: {
        'version': version,
        'scheduledAt': ?scheduledAt?.toUtc().toIso8601String(),
      },
      options: _options,
    );
    return _read(response.data);
  }

  static String _one(String id) => AppConstants.announcementEndpoint
      .replaceFirst('{id}', Uri.encodeComponent(id));

  static Announcement _read(Object? body) =>
      AnnouncementWire.fromJson(body) ??
      (throw const FormatException('Communiqué illisible'));
}
